#1. Plantilla de Lanzamiento (Sustituye el aws_instance individual)
resource "aws_launch_template" "web" {
  name_prefix   = "lt-${var.environment}-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  #DISCO GP3
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = var.root_volume_size
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  network_interfaces {
    associate_public_ip_address = false #subredes privadas detras del ALB
    security_groups             = [var.ec2_security_group_id]
  }

  #Script de User data en codificación base 64 para Launch Template
  user_data = base64encode(<<-EOF
        #!/bin/bash
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y
        apt-get install -y nginx
        echo "<h1>Servidor Web Nginx - Entorno: ${var.environment}</h1>" > &var/www/html/index.html
        systemctl enable --now nginx
        EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "WebServer-ASG-${var.environment}"
      Environment = var.environment
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

#2 . Grupo de Auto Escalado (ASG)
resource "aws_autoscaling_group" "web_asg" {
  name_prefix         = "asg-${var.environment}-"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [var.target_group_arn]

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  force_delete              = true
  health_check_type         = "ELB" #Revisa el estado de salud a traves del ELB
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "web-asg-instance-${var.environment}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
