output "bucket_id" {
  description = "ID/Nombre del bucket S3"
  value       = aws_s3_bucket.frontend.id
}

output "bucket_arn" {
  description = "ARN del bucket S3"
  value       = aws_s3_bucket.frontend.arn
}

output "webside_endpoint" {
  description = "Endpoint web estático del bucket S3"
  value       = aws_s3_bucket_website_configuration.frontend.website_endpoint
}

