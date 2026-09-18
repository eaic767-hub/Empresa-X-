module "vpc_staging" {
  source = "../../modules/vpc"

  vpc_cidr            = "10.1.0.0/16" #OJO TIENE RED DIFERENTE A DEV [10.0.0.0/16]
  public_subnet_cidr  = "10.1.1.0/24"
  private_subnet_cidr = "10.1.2.0/24"
  environment         = var.environment
  aws_region          = var.aws_region
}

module "ec2_staging" {
  source = "../../modules/ec2"

  environment      = var.environment
  vpc_id           = module.vpc_staging.vpc_id
  public_subnet_id = module.vpc_staging.public_subnet_id
  instance_type    = var.instance_type
  public_key_path  = var.public_key_path
  root_volume_size = var.root_volume_size
}

module "rds_dev" {
  source = "../../modules/rds"

  environment           = var.environment
  vpc_id                = module.vpc_dev.vpc_id
  private_subnet_ids    = [module.vpc_dev.private_subnet_id, module.vpc_dev.public_subnet_id]
  ec2_security_group_id = module.ec2_dev.security_group_id
  db_name               = var.db_name
  db_user               = var.db_user
  db_password           = var.db_password
}