#1. Bucket S3 para alojar el Frontend
resource "aws_s3_bucket" "frontend" {
  bucket        = "${var.bucket_name}-${var.environment}"
  force_destroy = true #Permite limpiar el bucket si se destruye el entorno teniendo contenido

  tags = {
    Name        = "Frontend-Bucket-${var.environment}"
    Environment = var.environment
  }
}

#2. Bloqueo de acceso público directo (Buenas practicas DevSecOps: todo pasa por el CloudFront)
resource "aws_S3_bucket_public_access_block" "frontend_public_block" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#3. COnfiguración del Hosting Web Estático
resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html" #Redirección estandar para SPAs (React,Vue,Angular)
  }
}

