# 1. Rol IAM para el planificador de AWS (Scheduler)
resource "aws_iam_role" "scheduler_role" {
  name = "scheduler-asg-rds-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
      }
    ]
  })
}

# 2. Permisos de IAM para modificar ASG y detener/iniciar RDS
resource "aws_iam_role_policy" "scheduler_policy" {
  name = "scheduler-asg-rds-policy-${var.environment}"
  role = aws_iam_role.scheduler_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:UpdateAutoScalingGroup",
          "rds:StartDBInstance",
          "rds:StopDBInstance"
        ]
        Resource = "*"
      }
    ]
  })
}

# ==========================================
# 3. ACCIONES DE APAGADO (8:00 PM Lunes-Viernes)
# ==========================================

# 3.1 Apagar Servidores Web (Seta ASG en 0)
resource "aws_scheduler_schedule" "stop_dev_asg" {
  name       = "stop-dev-asg"
  group_name = "default"

  schedule_expression = "cron(0 20 ? * MON-FRI *)"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:autoscaling:updateAutoScalingGroup"
    role_arn = aws_iam_role.scheduler_role.arn

    input = jsonencode({
      AutoScalingGroupName = module.asg.asg_name
      MinSize              = 0
      DesiredCapacity      = 0
    })
  }
}

# 3.2 Apagar Base de Datos RDS
resource "aws_scheduler_schedule" "stop_dev_rds" {
  name       = "stop-dev-rds"
  group_name = "default"

  schedule_expression = "cron(0 20 ? * MON-FRI *)"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:rds:stopDBInstance"
    role_arn = aws_iam_role.scheduler_role.arn

    input = jsonencode({
      DbInstanceIdentifier = module.rds_dev.db_instance_id # Asegúrate de que este output exista en tu modulo rds
    })
  }
}

# ==========================================
# 4. ACCIONES DE ENCENDIDO (7:00 AM Lunes-Viernes)
# ==========================================

# 4.1 Encender Base de Datos RDS (Primero la BD para que las APIS encuentren conexión)
resource "aws_scheduler_schedule" "start_dev_rds" {
  name       = "start-dev-rds"
  group_name = "default"

  schedule_expression = "cron(0 7 ? * MON-FRI *)"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:rds:startDBInstance"
    role_arn = aws_iam_role.scheduler_role.arn

    input = jsonencode({
      DbInstanceIdentifier = module.rds_dev.db_instance_id
    })
  }
}

# 4.2 Encender Servidores Web (Seta ASG en 1)
resource "aws_scheduler_schedule" "start_dev_asg" {
  name       = "start-dev-asg"
  group_name = "default"

  schedule_expression = "cron(5 7 ? * MON-FRI *)" # Levanta a las 7:05 AM tras arrancar la BD

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:autoscaling:updateAutoScalingGroup"
    role_arn = aws_iam_role.scheduler_role.arn

    input = jsonencode({
      AutoScalingGroupName = module.asg.asg_name
      MinSize              = 1
      DesiredCapacity      = 1
    })
  }
}
