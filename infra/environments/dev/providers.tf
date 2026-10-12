terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "terraform-bucket-empresax-2026-v1"
    key     = "dev/terraform.tfstate" #IMPORTANTE ESTA CLAVE DETERMINA MI ESPACIO DE TRABAJO SIN AFECTAR A LOS DEMAS
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region
}
