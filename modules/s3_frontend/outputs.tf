output "bucket_id" {
  description = "ID/Nombre del bucket S3"
  value       = aws_s3_bucket.frontend.id
}

output "cloudfront_domain_name" {
  description = "Dominio público HTTPS de CloudFront para acceder a la Web"
  value       = aws_cloudfront_distribution.frontend_cdn.domain_name
}

output "cloudfront_distribution_id" {
  description = "ID de la distribución de CloudFront (necesario para invalidar caché en su CI/CD)"
  value       = aws_cloudfront_distribution.frontend_cdn.id
}
