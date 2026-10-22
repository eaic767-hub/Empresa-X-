module "vpc_dev" {
  source = "../../modules/vpc"

  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidr  = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"
  environment         = var.environment
  aws_region          = var.aws_region
  resource_prefix     = var.resource_prefix # <--- Pasamos el prefijo
}

module "rds_dev" {
  source                = "../../modules/rds"
  environment           = var.environment
  resource_prefix       = var.resource_prefix # <--- Pasamos el prefijo
  vpc_id                = module.vpc_dev.vpc_id
  ec2_security_group_id = module.ec2.ec2_security_group_id
  private_subnet_ids    = module.vpc_dev.private_subnet_ids

  engine      = "mysql"
  db_name     = var.db_name
  db_user     = var.db_user
  db_password = var.db_password
}

# Modulo de Frontend (Almacenamiento S3)
module "frontend" {
  source = "../../modules/s3_frontend"

  environment     = var.environment
  resource_prefix = var.resource_prefix         # <--- Pasamos el prefijo
  bucket_name     = "frontend-empresax-pp-2026" # Base genérica, el módulo le agregará el sufijo dinámico
  alb_dns_name    = module.alb.alb_dns_name
}

# Modulo de ECR
module "ecr" {
  source = "../../modules/ecr"

  repository_name = "empresa-x-backend"
  resource_prefix = var.resource_prefix # <--- Pasamos el prefijo

  tags = {
    Environment = var.environment
    Project     = "EmpresaX"
  }
}

# Modulo EC2
module "ec2" {
  source            = "../../modules/ec2"
  environment       = var.environment
  resource_prefix   = var.resource_prefix # <--- Pasamos el prefijo
  vpc_id            = module.vpc_dev.vpc_id
  public_key_path   = var.public_key_path
  private_subnet_id = module.vpc_dev.private_subnet_ids[0]
}

# Modulo APPLICATION LOAD BALANCER 
module "alb" {
  source                = "../../modules/alb"
  environment           = var.environment
  resource_prefix       = var.resource_prefix # <--- Pasamos el prefijo
  vpc_id                = module.vpc_dev.vpc_id
  public_subnet_ids     = module.vpc_dev.public_subnet_ids
  alb_security_group_id = module.ec2.alb_security_group_id
}

# Modulo AUTOSCALING GROUP
module "asg" {
  source                = "../../modules/asg"
  environment           = var.environment
  resource_prefix       = var.resource_prefix # <--- Pasamos el prefijo
  vpc_id                = module.vpc_dev.vpc_id
  private_subnet_ids    = module.vpc_dev.private_subnet_ids
  target_group_arn      = module.alb.target_group_arn
  ami_id                = module.ec2.ami_id
  instance_type         = var.instance_type
  instance_profile_name = module.ec2.instance_profile_name
  ec2_security_group_id = module.ec2.ec2_security_group_id
  root_volume_size      = var.root_volume_size
}

# Modulo DE MONITOREO PROMETHEUS + GRAFANA
module "monitoring" {
  source                = "../../modules/monitoring"
  environment           = var.environment
  resource_prefix       = var.resource_prefix # <--- Pasamos el prefijo
  vpc_id                = module.vpc_dev.vpc_id
  vpc_cidr              = module.vpc_dev.vpc_cidr
  public_subnet_id      = module.vpc_dev.public_subnet_ids[0]
  ami_id                = module.ec2.ami_id
  instance_profile_name = module.ec2.instance_profile_name
}
#-------------------------------------------------K8S-----------------------------------------------------------------
# Modulo DE K8S EKS
module "EKS" {
  source          = "../../modules/EKS"
  environment     = var.environment
  resource_prefix = var.resource_prefix # <--- Pasamos el prefijo
  subnet_ids      = module.vpc_dev.public_subnet_ids
}

# Módulo IRSA para el AWS Load Balancer Controller
module "aws_load_balancer_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                              = "aws-load-balancer-controller-${module.EKS.cluster_name}"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.EKS.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

# ServiceAccount creada nativamente por Terraform en Kubernetes
resource "kubernetes_service_account_v1" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = module.aws_load_balancer_controller_irsa.iam_role_arn
    }
  }

  depends_on = [
    module.EKS,
    module.aws_load_balancer_controller_irsa
  ]
}
