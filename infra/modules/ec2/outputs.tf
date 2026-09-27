output "server_public_ip" {
  value = aws_instance.web_server.public_ip
}

output "security_group_id" {
  description = "ID del Security Group creado para el servidor web"
  value       = aws_security_group.web_sg.id
}

output "instance_id" {
  description = "ID de la instancia EC2 para automatización"
  value       = aws_instance.web_server.id
}
