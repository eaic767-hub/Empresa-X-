output "rds_endpoint" {
  description = "Punto de enlace (Endpoint) para conectarse a la Base de Datos"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_security_group_id" {
  description = "ID del Security Group de RDS"
  value       = aws_security_group.rds_sg.id
}

output "db_instance_id" {
  description = "El identificador de la instancia DB RDS para el scheduler"
  value       = aws_db_instance.postgres.identifier
}
