output "ami_id" {
  description = "ID de la AMI de Ubuntu seleccionada"
  value       = data.aws_ami.ubuntu.id
}

output "instance_profile_name" {
  value       = aws_iam_instance_profile.backend_profile.name
  description = "Nombre de la Instance Profile para la EC2"
}

output "backend_role_arn" {
  value       = aws_iam_role.backend_role.arn
  description = "ARN del rol de IAM para el backend"
}

output "ec2_security_group_id" {
  description = "ID del Security Group asignado a las instancias EC2"
  value       = aws_security_group.web_sg.id
}

output "alb_security_group_id" {
  description = "ID del Security Group asignado al ALB"
  value       = aws_security_group.alb_sg.id
}

