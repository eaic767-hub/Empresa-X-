terraform {
  backend "s3" {
    bucket         = "empresa-x-terraform-state-dev" # Un nombre único para tu bucket de estados
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks-dev" # Opcional pero recomendado para bloquear estados concurrentes
  }
}
