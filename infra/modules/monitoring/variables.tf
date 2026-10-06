variable "environment" {
  type        = string
  description = "Nombre del entorno (ej. dev, staging, prod)"
}

variable "vpc_id" {
  type        = string
  description = "ID de la VPC donde se desplegará el servidor de monitoreo"
}

variable "vpc_cidr" {
  type        = string
  description = "Bloque CIDR de la VPC para reglas de seguridad internas"
}

variable "public_subnet_id" {
  type        = string
  description = "ID de la subnet pública donde residirá la EC2 de monitoreo"
}

variable "ami_id" {
  type        = string
  description = "ID de la AMI de Ubuntu a utilizar"
}

variable "instance_profile_name" {
  type        = string
  description = "Nombre del IAM Instance Profile para SSM"
}

variable "instance_type" {
  type        = string
  description = "Tipo de instancia EC2"
  default     = "t3.small" # t3.small es ideal para correr Prometheus + Grafana juntos
}
