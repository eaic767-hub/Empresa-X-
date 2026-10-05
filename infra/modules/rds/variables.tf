variable "environment" {
  type        = string
  description = "Nombre del Entorno"
}

variable "vpc_id" {
  type        = string
  description = "ID de la VPC donde estara el Security Group de la BD"
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "ec2_security_group_id" {
  type        = string
  description = "ID del Security Group de la EC2 para permitirle el acceso a la BD"
}

#------------CONFIGURACIÓN DINÁMICA DEL MOTOR---------------
variable "engine" {
  type        = string
  description = "Motor de la base de datos: 'postgres' o 'mysql' "
  default     = "postgres"

  validation {
    condition     = contains(["postgres", "mysql"], var.engine)
    error_message = "El motor debe ser 'postgres' o 'mysql'. "
  }
}

variable "engine_version" {
  type        = string
  description = "Version del Motor (Ej: '15' para postegres, '8.0' para mysql)"
  default     = null #Se asigna dinámicamente, sino se especifica. 
}

variable "instance_class" {
  type        = string
  description = "Tipo de Instancia RDS"
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  type        = number
  description = "Almacenamiento inicial en GB"
  default     = 20
}

variable "max_allocated_storage" {
  type        = number
  description = "Almacenamiento máximo para el autoscaling de disco"
  default     = 100
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
