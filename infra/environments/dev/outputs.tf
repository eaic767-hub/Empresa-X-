#---RED Y SERVIDOR (BACKEND)---
output "vpc_id" {
  value = module.vpc_dev.vpc_id
}

#---BASE DE DATOS (RDS)---
output "rds_endpoint" {
  description = "Endpoint de conexión para la Base de Datos RDS"
  value       = module.rds_dev.rds_endpoint
}

#---FRONTEND (S3 +CLOUDFRONT)---
output "frontend_bucket_name" {
  description = "Nombre del bucket S3 para el Frontend"
  value       = module.frontend.bucket_id
}

output "frontend_cloudfront_url" {
  description = "URL pública del Frontend (HTTPS)"
  value       = "https://${module.frontend.cloudfront_domain_name}"
}

output "cloudfront_distribution_id" {
  description = "ID de CloudFront para invalidaciones"
  value       = module.frontend.cloudfront_distribution_id
}

#--- URL EC2---

output "ecr_repository_url" {
  description = "URL del repositorio ECR para subir imagenes"
  value       = module.ecr.repository_url
}

output "backend_public_ip" {
  description = "IP publica de la instancia EC2 backend"
  value       = module.ec2.server_public_ip
}
