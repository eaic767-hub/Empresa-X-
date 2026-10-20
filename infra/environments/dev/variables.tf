variable "aws_region" {
  type        = string
  description = "Region de AWS para el despliegue"
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "Entorno de Trabajo"
  default     = "dev"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "public_key_path" {
  type    = string
  default = "nginx-server.key.pub"
}

variable "root_volume_size" {
  description = "tamaño de disco de la instancia en Gb"
  type        = number
  default     = 8
}

variable "db_name" {
  type        = string
  description = "Nombre inicial de la BD"
  default     = "appdb"
}

variable "db_user" {
  type        = string
  description = "Usuario Maestro de la BD"
  default     = "dbadmin"
}

variable "db_password" {
  type        = string
  description = "Contraseña de la BD"
  sensitive   = true #OJO IMPORTANTE PORQUE NO MUESTRA EL TEXTO PLANO EN CONSOLA O TRAZAS EN TERRAFORM APPLY 
  default     = ""
}

variable "resource_prefix" {
  type        = string
  description = "Prefijo unico para aislar recursos en sandbox o pruebas"
  default     = ""
}
