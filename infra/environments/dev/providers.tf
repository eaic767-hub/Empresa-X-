terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.45.0" # Forzamos una versión suficientemente moderna que reconozca los atributos del EKS
    }
  }

  backend "s3" {
    bucket  = "terraform-bucket-empresax-2026-v1"
    key     = "dev/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

# Proveedor de Kubernetes para que Terraform pueda crear recursos dentro de EKS
provider "kubernetes" {
  host     = module.EKS.cluster_endpoint
  insecure = true

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.EKS.cluster_name]
    command     = "aws"
  }
}
