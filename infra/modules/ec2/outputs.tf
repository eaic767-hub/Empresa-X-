output "ami_id" {
  description = "ID de la AMI de Ubuntu seleccionada"
  value       = data.aws_ami.ubuntu.id
}

output "key_name" {
  description = "Nombre de la clave SSH registrada"
  value       = aws_key_pair.web_key.key_name
}

output "ec2_security_group_id" {
  description = "ID del Security Group asignado a las instancias EC2"
  value       = aws_security_group.web_sg.id
}

output "alb_security_group_id" {
  description = "ID del Security Group asignado al ALB"
  value       = aws_security_group.alb_sg.id
}
