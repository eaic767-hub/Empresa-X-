variable "aws_region" {
  type        = string
  description = "Region de AWS para el despliegue"
}

variable "environment" {
  type        = string
  description = "Entorno de Trabajo"
}

variable "instance_type" {
  type = string
}

variable "public_key_path" {
  type = string
}

variable "root_volume_size" {
  description = "tamaño de disco de la instancia en Gb"
  type        = number
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
}
