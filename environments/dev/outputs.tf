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