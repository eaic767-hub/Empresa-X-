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
# IAM ROLE + INSTANCE PROFILE (SSM, SDK, ECR & Prometheus EC2 SD)
#------------------------------------------------------------------------------

# 1. Rol de IAM que asumirán las instancias EC2
resource "aws_iam_role" "backend_role" {
  name = "ec2-backend-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
  }
}

# 2. Política para permitir que el Backend (vía AWS SDK) lea de Secrets Manager
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

# 4. Adjuntar política administrada de SSM (Permite conexión por Session Manager sin llaves SSH)
resource "aws_iam_role_policy_attachment" "attach_ssm" {
  role       = aws_iam_role.backend_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# 5. Adjuntar política administrada de ECR (Permite hacer pull de imágenes Docker)
resource "aws_iam_role_policy_attachment" "attach_ecr" {
  role       = aws_iam_role.backend_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# 6. Adjuntar política de lectura de EC2 (Permite a Prometheus consultar la API de AWS para ec2_sd_configs)
resource "aws_iam_role_policy_attachment" "attach_ec2_read" {
  role       = aws_iam_role.backend_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

# 7. Instance Profile para pasarle este Rol a las EC2
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

  #TRAFICO DE MONITOREO: Node Exporter para Prometheus (solo interno de VPC)

  ingress {
    description = "Node Exporter para Prometheus"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr] # LA DECLARADA EN LA VPC en variables
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

#------------------------------------------------------------------------------
# EC2 INSTANCE / BACKEND
#------------------------------------------------------------------------------

resource "aws_instance" "backend" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # Importante: Asignación del Instance Profile con SSM y permisos SDK
  iam_instance_profile = aws_iam_instance_profile.backend_profile.name

  # Fuerza la recreación automática de la EC2 si cambia el user_data
  user_data_replace_on_change = true

  # Script de User Data con Node Exporter
  user_data = base64encode(<<-EOF
        #!/bin/bash
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y
        apt-get install -y curl

        # Instalación de Node Exporter
        NODE_EXPORTER_VERSION="1.7.0"
        useradd --no-create-home --shell /bin/false node_exporter 2>/dev/null || true

        cd /tmp
        curl -LO "https://github.com/prometheus/node_exporter/releases/download/v$NODE_EXPORTER_VERSION/node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz"
        tar -xvf "node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz"
        mv "node_exporter-$NODE_EXPORTER_VERSION.linux-amd64/node_exporter" /usr/local/bin/
        chown node_exporter:node_exporter /usr/local/bin/node_exporter

        # Crear Servicio Systemd
        cat <<SERVICE > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
SERVICE

        systemctl daemon-reload
        systemctl enable --now node_exporter
        EOF
  )

  tags = {
    Name        = "backend-server-${var.environment}"
    Environment = var.environment
  }
}
