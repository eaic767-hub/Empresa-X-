#1. nombre unico para la cubeta s3 (S3 requiere nombres globales unicos)
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "terraform-bucket-empresax-2026-v1" #si este nombre existe se cambia por uno unico
  force_destroy = true                             #permite borrar la cubeta con destroy en pruebas
}

#2. Habilitar el control de versiones para no perder estados anteriores
resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

#3. Cifrado del lado del servidor para proteger la información sensible
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_crypto" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

#4. Tabla de DynamoDB para el bloqueo de estado (State Locking)
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks-lab"
  billing_mode = "PAY_PER_REQUEST" #pago por uso (económico para laboratorios)
  hash_key     = "LockID"          #Clave obligatoria que usa terraform

  attribute {
    name = "LockID"
    type = "S" #Es de tipo string
  }
}