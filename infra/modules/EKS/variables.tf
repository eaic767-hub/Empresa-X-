variable "environment" {
  type        = string
  description = "Entorno de despliegue (Dev,prod,staging,etc)"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Lista de Ids de Subredes donde se despegara el cluster de EKS"
}
