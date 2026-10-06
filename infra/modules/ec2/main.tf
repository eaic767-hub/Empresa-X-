data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

#------------------------------------------------------------------------------
#IAM ROLE + INSTANCE PROFILE (SSM &AWS SDK para Backend)
#-------------------------------------------------------------------------------

#1. Rol de IAM que asumiran las instancias EC2
resource "aws_iam_role" "backend_role" {
  name = "ec2-backend-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2010-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "ec2.amazon.com" }
      }
    ]
  })

  tags = {
    Environment = var.environment
  }
}

#2. Politica para permitir que el Backend 8via AWS SDK ) lea de Secrets Manager
resource "aws_iam_policy" "backend_sdk_policy" {
  name        = "ec2-backend-sdk-policy-${var.environment}"
  description = "Permisos de AWS SDK para que el backend pueda leer Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
      }
    ]
  })
}

# 3. Adjuntar política del SDK al Rol
resource "aws_iam_role_policy_attachment" "attach_sdk" {
  role       = aws_iam_role.backend_role.name
  policy_arn = aws_iam_policy.backend_sdk_policy.arn
}

# 4. Adjuntar política administrada de SSM (Conexión segura sin SSH / sin key pair)
resource "aws_iam_role_policy_attachment" "attach_ssm" {
  role       = aws_iam_role.backend_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# 5. Instance Profile para pasarle este Rol a las EC2
resource "aws_iam_instance_profile" "backend_profile" {
  name = "ec2-backend-profile-${var.environment}"
  role = aws_iam_role.backend_role.name
}

#SECURITY GROUPS
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg-${var.environment}"
  description = "Permitir trafico HTTP y HTTPS desde Internet al ALB"
  vpc_id      = var.vpc_id

  #TRAFICO DE PUERTOS  HTTP Y HTTPS
  ingress {
    description = "Acceso HTTP publico"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Acceso HTTPS publico"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Salida total a Internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "alb-sg-${var.environment}"
    Environment = var.environment
    VpcId       = var.vpc_id # <- Etiqueta para que el sg lleve la etiqueta del vpn de despliegue para auditoria
  }
}

#4. Security Group para las instancias EC2 (PRIVADO/PROTEGIDO)
resource "aws_security_group" "web_sg" {
  name        = "web-server-sg-${var.environment}"
  description = "Permitir trafico exclusivamente desde el ALB y SSH de administracion"
  vpc_id      = var.vpc_id

  #TRAFICO WEB: UNICAMENTE PROVENIENTE DEL ALB
  ingress {
    description     = "HTTP solo desde el ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  #SALIDA A INTERNET (Para descargar contenedores de ECR y actualizar paquetes)
  egress {
    description = "Salida total a Internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "web-sg-${var.environment}"
    Environment = var.environment
    VpcId       = var.vpc_id
  }
}
