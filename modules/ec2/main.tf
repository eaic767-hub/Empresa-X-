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
  key_name   = "${var.environment}-web-key"
  public_key = file(var.public_key_path)
}

resource "aws_security_group" "web_sg" {
  name        = "web-server-sg-${var.environment}"
  description = "Permitir trafico HTTP, HTTPS y SSH"
  vpc_id      = var.vpc_id

  ingress {
    description = "Acceso HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Acceso SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Acceso HTTPS"
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
    Name        = "web-sg-${var.environment}"
    Environment = var.environment
    VpcId       = var.vpc_id # <- Etiqueta para que el sg lleve la etiqueta del vpn de despliegue para auditoria
  }
}

resource "aws_instance" "web_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.web_key.key_name
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  #NUEVO BLOQUE: Configuración de almacenamiento
  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = <<-EOF
        #!/bin/bash
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y
        apt-get install -y nginx
        echo "<h1>Servidor Web Nginx - Entorno: ${var.environment}<h1>" > /var/www/html/index.html
        systemctl enable --now nginx
        EOF

  user_data_replace_on_change = true

  tags = {
    Name        = "WebServer-${var.environment}"
    Environment = var.environment
  }
}
