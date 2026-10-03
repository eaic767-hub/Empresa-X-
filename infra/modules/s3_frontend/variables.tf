variable "environment" {
  description = "Entorno de despliegue dev"
  type        = string
}

variable "bucket_name" {
  description = "Nombre único para el bucket S3 del frontend"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS Name del Application Load Balancer para enrutar el tráfico de /api/*"
  type        = string
  default     = ""
}
