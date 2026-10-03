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

resource "aws_key_pair" "web_key" {
  key_name   = "${var.environment}-web-key-v4"
  public_key = file(var.public_key_path)
}

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

  #ACCESO SSH DE ADMINISTRACIÓN (Puerto 22)
  ingress {
    description = "Acceso SSH de administracion"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #NOTA: SE RECOMIENDA EN PROD RESTRINGIR LA IP DEL SYSADMIN
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
