resource "aws_ecr_repository" "this" {
  name                 = var.resource_prefix != "" ? "${var.repository_name}-${var.resource_prefix}" : var.repository_name
  image_tag_mutability = "MUTABLE"

  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(
    var.tags,
    {
      Name = var.resource_prefix != "" ? "${var.repository_name}-${var.resource_prefix}" : var.repository_name
    }
  )
}

# Regla de ciclo de vida: Elimina imágenes viejas para no acumular costos en AWS
resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Mantener solo las ultimas 5 imagenes"
        selection = {
          tagStatus   = "any"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 14
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
