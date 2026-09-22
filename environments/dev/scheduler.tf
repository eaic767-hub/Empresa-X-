# 1. Rol IAM para el planificador de AWS (Scheduler)
resource "aws_iam_role" "scheduler_role" {
  name = "scheduler-ec2-rds-role-${var.environment}"

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

# 2. Permisos de IAM para apagar y encender EC2/RDS
resource "aws_iam_role_policy" "scheduler_policy" {
  name = "scheduler-ec2-rds-policy-${var.environment}"
  role = aws_iam_role.scheduler_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances",
          "rds:StartDBInstance",
          "rds:StopDBInstance"
        ]
        Resource = "*"
      }
    ]
  })
}

# 3. Regla para APAGAR a las 8:00 PM (Lunes a Viernes)
resource "aws_scheduler_schedule" "stop_dev_environment" {
  name       = "stop-dev-resources"
  group_name = "default"

  schedule_expression = "cron(0 20 ? * MON-FRI *)"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:stopInstances"
    role_arn = aws_iam_role.scheduler_role.arn

    input = jsonencode({
      InstanceIds = [module.ec2_dev.instance_id]
    })
  }
}

# 4. Regla para ENCENDER a las 7:00 AM (Lunes a Viernes)
resource "aws_scheduler_schedule" "start_dev_environment" {
  name       = "start-dev-resources"
  group_name = "default"

  schedule_expression = "cron(0 7 ? * MON-FRI *)"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:startInstances"
    role_arn = aws_iam_role.scheduler_role.arn

    input = jsonencode({
      InstanceIds = [module.ec2_dev.instance_id]
    })
  }
}
