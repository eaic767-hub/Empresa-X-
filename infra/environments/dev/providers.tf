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

# Proveedor de Kubernetes configurado de forma segura para evitar errores al crearse el clúster
provider "kubernetes" {
  host     = try(module.EKS.cluster_endpoint, "")
  insecure = true

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", try(module.EKS.cluster_name, "dummy")]
    command     = "aws"
  }
}
