#1. Grupo de Subredes para RDS (Exige almenos subredes en la VPC)
resource "aws_db_subnet_group" "rds_subnet_group" {
    name = "${var.environment}-rds-subnet-group"
    subnet_ids =var.private_subnet_ids #<-- SUBRED PRIVADA DEFINIDA EN VPC

    tags ={
        Name = "${var.environment}-rds-subnet-group"
        environment =var.environment
    }
}

#2. SG exclusivo para la BD
resource "aws_security_group" "rds_sg" {
    name = "${var.environment}-rds-sg"
    description = "Permitir trafico solo desde el servidor web EC2"
    vpc_id =var.vpc_id

    #REGLA DE ENTRADA : solo permite el puerto 5432 desde el SG de la EC2
    ingress {
        description ="Acceso PostgreSQL desde EC2"
        from_port =5432
        to_port =5432
        protocol="tcp"
        security_groups = [var.ec2_security_group_id] # <-- Aislamiento de Seguridad Real
    }

    egress{
        from_port=0
        to_port=0
        protocol="-1"
        cidr_blocks=["0.0.0.0/0"]
    }

    tags= {
        Name ="${var.environment}-rds-sg"
        Environment = var.environment
    }
}

#3. Instancia de DB PostgreSQL (Engine Gratuito/Micro)
resource "aws_db_instance" "postgres" {
  allocated_storage      = 20 #ese 20 es el almacenamiento de la SSD
  max_allocated_storage  = 100
  db_name                = var.db_name
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"
  username               = var.db_user
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true

  tags = {
    Name = "${var.environment}-postgres-db"
    Environment = var.environment
  }
}