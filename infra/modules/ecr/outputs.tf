output "repository_url" {
  description = "URL del repositorio ECR"
  value       = aws_ecr_repository.this.repository_url
}

output "repository_arn" {
  description = "ARN del repositorio ECR"
  value       = aws_ecr_repository.this.arn
}

output "ubuntu_ami_id" {
  description = "ID de la AMI de Ubuntu obtenida vía data source"
  value       = data.aws_ami.ubuntu.id
}

output "instance_profile_name" {
  description = "Nombre del Instance Profile para SSM/IAM"
  value       = aws_iam_instance_profile.backend_profile.name
}

output "web_sg_id" {
  description = "ID del Security Group del backend"
  value       = aws_security_group.web_sg.id
}
