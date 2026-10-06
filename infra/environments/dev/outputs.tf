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

output "alb_dns_name" {
  description = "DNS del Load Balancer"
  value       = module.alb.alb_dns_name
}

# Outputs de Monitoreo
output "grafana_dashboard_url" {
  description = "Acceso directo al panel de Grafana"
  value       = module.monitoring.grafana_url
}

output "prometheus_dashboard_url" {
  description = "Acceso directo a la consola de Prometheus"
  value       = module.monitoring.prometheus_url
}

