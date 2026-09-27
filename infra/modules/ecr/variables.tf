variable "repository_name" {
  description = "Nombre del Repositorio ECR"
  type        = string
}

variable "tags" {
  description = "Etiquetas para el recurso"
  type        = map(string)
  default     = {}
}

