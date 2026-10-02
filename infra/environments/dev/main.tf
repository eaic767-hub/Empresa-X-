module "vpc_dev" {
  source = "../../modules/vpc"

  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidr  = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"
  environment         = var.environment
  aws_region          = var.aws_region
}

module "rds_dev" {
  source = "../../modules/rds"

  environment           = var.environment
  vpc_id                = module.vpc_dev.vpc_id
  private_subnet_ids    = [module.vpc_dev.private_subnet_id, module.vpc_dev.public_subnet_id]
  ec2_security_group_id = module.ec2.ec2_security_group_id
  db_name               = var.db_name
  db_user               = var.db_user
  db_password           = var.db_password
}

#Modulo de Frontend (Almacenamiento S3)
module "frontend" {
  source = "../../modules/s3_frontend"

  environment = var.environment
  bucket_name = "frontend-empresax-pp-dev-2026"
}

#modulo de ECR (DOCKER, DOCKERCOMPOSE AND MODULE ECR)
module "ecr" {
  source = "../../modules/ecr"

  repository_name = "empresa-x-backend-dev"

  tags = {
    Environment = "dev"
    Project     = "EmpresaX"
  }
}
# modulo EC2 (SG, AMI, KEY SSH, ENTRADAS POR SUBNET PUBLICAS A ALB Y PRIVADAS )
module "ec2" {
  source          = "../../modules/ec2"
  environment     = var.environment
  vpc_id          = module.vpc_dev.vpc_id
  public_key_path = var.public_key_path
}

#MODULO APPLICATION LOAD BALANCER 
module "alb" {
  source                = "../../modules/alb"
  environment           = var.environment
  vpc_id                = module.vpc_dev.vpc_id
  public_subnets_ids    = module.vpc_dev.public_subnet_ids
  alb_security_group_id = module.ec2.alb_security_group_id
}
#MODULO AUTOSCALLING GROUP
module "asg" {
  source                = "../../modules/asg"
  environment           = var.environment
  vpc_id                = module.vpc_dev.vpc_id
  private_subnet_id     = module.vpc_dev.private_subnets_id
  target_group_arn      = module.alb.target_group_arn
  ami_id                = module.ec2.ami_id
  instance_type         = var.instance_type
  key_name              = module.ec2.key_name
  ec2_security_group_id = module.ec2.ec2_security_group_id
  root_volume_size      = var.root_volume_size
}
