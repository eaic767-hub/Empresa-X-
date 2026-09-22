terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # CONFIGURACIÓN DE BACKEND REMOTO 
  backend "s3" {
    bucket       = "terraform-bucket-empresax-2026-v1"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
  }
}

provider "aws" {
  region = var.aws_region
}