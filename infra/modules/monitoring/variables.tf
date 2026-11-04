variable "environment" {
  type        = string
  description = "Nombre del entorno (ej. dev, staging, prod)"
}

variable "resource_prefix" {
  type        = string
  default     = ""
  description = "Prefijo para los nombres de los recursos"
}

variable "cluster_name" {
  type        = string
  description = "Nombre del clúster EKS donde se desplegará Helm"
}

variable "cluster_endpoint" {
  type        = string
  description = "Endpoint del clúster EKS"
}

variable "cluster_certificate_authority_data" {
  type        = string
  description = "Certificado CA del clúster EKS"
}

variable "cluster_oidc_issuer_url" {
  type        = string
  description = "URL del emisor OIDC del clúster EKS"
}
