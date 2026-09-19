#---RED Y SERVIDOR (BACKEND)---
output "vpc_id" {
  value = module.vpc_dev.vpc_id
}

output "backend_public_ip" {
  description = "IP publica del servidor EC2 para despliegue de APIs"
  value       = module.ec2_dev.server_public_ip
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
