output "monitoring_instance_id" {
  description = "ID de la instancia EC2 de monitoreo"
  value       = aws_instance.monitoring_server.id
}

output "monitoring_public_ip" {
  description = "IP pública del servidor de monitoreo"
  value       = aws_instance.monitoring_server.public_ip
}

output "grafana_url" {
  description = "URL de acceso a Grafana UI"
  value       = "http://${aws_instance.monitoring_server.public_ip}:3000"
}

output "prometheus_url" {
  description = "URL de acceso a Prometheus UI"
  value       = "http://${aws_instance.monitoring_server.public_ip}:9090"
}
