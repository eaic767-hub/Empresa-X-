variable "environment" {
  description = "Entorno de despliegue dev"
  type        = string
}

variable "bucket_name" {
  description = "Nombre único para el bucket S3 del frontend"
  type        = string
}
