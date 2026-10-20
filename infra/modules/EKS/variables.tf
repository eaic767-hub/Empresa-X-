variable "environment" {
  type        = string
  description = "Entorno de despliegue (Dev,prod,staging,etc)"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Lista de Ids de Subredes donde se despegara el cluster de EKS"
}

variable "resource_prefix" {
  type    = string
  default = ""
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}
