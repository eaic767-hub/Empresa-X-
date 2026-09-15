output "rds_endpoint" {
  description = "Punto de enlace (Endpoint) para conectarse a la Base de Datos"
  value       = aws_db_instance.postgres.endpoint
}