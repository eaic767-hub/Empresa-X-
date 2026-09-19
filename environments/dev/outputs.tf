output "vpc_id" {
  value = module.vpc_dev.vpc_id
}

output "server_public_ip" {
  value = module.ec2_dev.server_public_ip
}

output "rds_endpoint" {
  description = "Endpoint de conexión para la Base de Datos RDS"
  value       = module.rds_dev.rds_endpoint
}

output "frontend_bucket_name" {
  description = "Nombre del bucket S3 para el Frontend"
  value       = module.frontend.bucket_id
}

output "frontend_webside_endpoint" {
  description = "Endpoint de S3 para acceder al frontend"
  value       = module.frontend.webside_endpoint
}

output "frontend_cloudfront_url" {
  description = "URL pública del Frontend (HTTPS)"
  value       = "https://${module.frontend.cloudfront_domain_name}"
}

output "cloudfront_distribution_id" {
  description = "ID de CloudFront para invalidaciones"
  value       = module.frontend.cloudfront_distribution_id
}
