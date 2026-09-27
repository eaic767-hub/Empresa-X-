output "staging_vpc_id" {
  value = module.vpc_staging.vpc_id
}

output "staging_server_ip" {
  value = module.ec2_staging.server_public_ip
}

output "staging_security_group_id" {
  description = "ID del Security Group de Staging"
  value       = module.ec2_staging.security_group_id
}

