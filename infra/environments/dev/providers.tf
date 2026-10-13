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

provider "aws" {
  region = var.aws_region
}
