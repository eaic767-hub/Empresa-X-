variable "environment" {
  description = "Entorno de ejecución dev"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC donde se desplegara el Target Group"
  type        = string
}

variable "public_subnets_ids" {
  description = "Lista de subredes públicas para el ALB"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "ID del Security Group Asignado al ALB"
  type        = string
}

variable "health_check_path" {
  description = "Ruta para el Health Check HTTP"
  type        = string
  default     = "/health.php"
}

variable "tags" {
  description = "Etiquetas comunes de recursos"
  type        = map(string)
  default     = {}
}

variable "certificate_arn" {
  description = "ARN del certificado SSL en AWS Certificate Manager (ACM). Si no se provee, no se crea el listener HTTPS."
  type        = string
  default     = ""
}
