#1. Determinación de Puerto y Versión por defecto segun motor
locals {
  db_port = var.engine == "postgres" ? 5432 : 3306

  default_engine_version = var.engine == "postgres" ? "15" : "8.0"
  engine_version         = var.engine_version != null ? var.engine_version : local.default_engine_version

  #Si no se envía contraseña, se usa la generada en Terraform
  master_password = var.db_password != "" ? var.db_password : random_password.rds_password.result
}

#2. Generación de Contraseña aleatoria segura
resource "ramdom_password" "rds_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

#3. Almacenamiento seguro en AWS Secrets Manager (Buenas practicas DevSecOps)
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.environment}-${var.engine}-db-credentials"
  recovery_window_in_days = var.environment == "prod" ? 30 : 0 # IMPORTANTE, EN DEV Y STAGING DESTRUYE AUTOMATICAMENTE LAS SECRETS MANAGER, EN PROD TARDA 30 DIAS.
}

resource "aws_secretsmanager_secret_version" "db_credentials_val" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    engine   = var.engine
    host     = aws_db_instance.this.address
    port     = local.db_port
    username = var.db_user
    password = local.master_password
    database = var.db_name
  })
}

#4. Grupo de Subredes para RDS
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.environment}-rds-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name        = "${var.environment}-rds-subnet-group"
    Environment = var.environment
  }
}

#5. Security Group dinamico segun el puerto del motor seleccionado
resource "aws_security_group" "rds_sg" {
  name        = "${var.environment}-${var.engine}-rds-sg"
  description = "Permitir trafico ${var.engine} solo desde las EC2 del ASG"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Acceso ${var.engine} desde EC2"
    from_port       = local.db_port
    to_port         = local.db_port
    protocol        = "tcp"
    security_groups = [var.ec2_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-${var.engine}-rds-sg"
    Environment = var.environment
  }
}

#6. Instancia unificada de RDS Multi-Engine
resource "aws_db_instance" "this" {
  identifier             = "${var.environment}-${var.engine}-db"
  allocated_storage      = var.allocated_storage
  max_allocated_storage  = var.max_allocated_storage
  db_name                = var.db_name
  engine                 = var.engine
  engine_version         = local.engine_version
  instance_class         = var.instance_class
  username               = var.db_user
  password               = local.master_password
  port                   = local.db_port
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true

  tags = {
    Name        = "${var.environment}-${var.engine}-db"
    Environment = var.environment
  }
}
