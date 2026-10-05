output "rds_endpoint" {
  description = "Punto de enlace (Endpoint) para conectarse a la Base de Datos"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_address" {
  description = "DNS/Host de la db (sin puerto)"
  value       = aws_db_instance.this.address
}

output "rds_port" {
  description = "Puerto configurado en la DB"
  value       = local.db_port
}

output "rds_security_group_id" {
  description = "ID del Security Group de RDS"
  value       = aws_security_group.rds_sg.id
}

output "db_instance_id" {
  description = "El identificador de la instancia DB RDS para el scheduler"
  value       = aws_db_instance.this.identifier
}

output "secret_arn" {
  description = "ARN del secreto guardado en AWS Secrets Manager"
  value       = aws_secretsmanager_secret.db_credentials.arn
}
