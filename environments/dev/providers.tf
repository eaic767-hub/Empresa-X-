terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
  }

  #CONFIGURACIÓN DE BACKEND REMOTO 
  #se identa para subir el tf primero y luego se quita el # para migrar el terraform.tfstate al bucket s3 con el lock state de DynamoDB_table
  backend "s3" {
    bucket       = "terraform-bucket-empresax-2026-v1"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true #dynamoDB_table = "nombre" 
    encrypt      = true
  }
}

provider "aws" {
  region = var.aws_region
}
