output "alb_id" {
  description = "ID del Application Load Balancer"
  value       = aws_lb.this.id
}

output "alb_arn" {
  description = "ARN del Load Balancer"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "Nombre DNS del ALB"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Zone ID del ALB (util para mapear registros DNS A/ALIAS en Route 53)"
  value       = aws_lb.this.zone_id
}

output "target_group_arn" {
  description = "ARN del Target Group para asociar al Auto Scaling Group o K8s"
  value       = aws_lb_target_group.this.arn
}

output "http_listener_arn" {
  description = "ARN del Listener HTTP (Puerto 80)"
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "ARN del Listener HTTPS (Puerto 443), si esta habilitado"
  value       = length(aws_lb_listener.https) > 0 ? aws_lb_listener.https[0].arn : null
}
