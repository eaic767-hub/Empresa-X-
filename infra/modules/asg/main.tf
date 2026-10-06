# 1. Plantilla de Lanzamiento (Sustituye el aws_instance individual)
resource "aws_launch_template" "web" {
  name_prefix   = "lt-${var.environment}-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  #Se asigna el IAM Instance profile para SSM+AWS SDK
  iam_instance_profile {
    name = var.instance_profile_name
  }

  # DISCO GP3
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = var.root_volume_size
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  # Asignación de IP pública para permitir salida a Internet (descarga de paquetes/Nginx)
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.ec2_security_group_id]
  }

  # Script de User data limpio para el despliegue de Nginx
  # Script de User data limpio para el despliegue de Nginx con Node Exporter
  user_data = base64encode(<<-EOF
        #!/bin/bash
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y
        apt-get install -y nginx curl

        # 1. Configuración de Nginx
        echo "<h1>Servidor Web Nginx - Entorno: ${var.environment} (Subred Privada + NAT)</h1>" > /var/www/html/index.html
        systemctl enable --now nginx

        # 2. Instalación de Node Exporter para Prometheus
        NODE_EXPORTER_VERSION="1.7.0"
        useradd --no-create-home --shell /bin/false node_exporter || true

        cd /tmp
        curl -LO "https://github.com/prometheus/node_exporter/releases/download/v$NODE_EXPORTER_VERSION/node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz"
        tar -xvf "node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz"
        mv "node_exporter-$NODE_EXPORTER_VERSION.linux-amd64/node_exporter" /usr/local/bin/
        chown node_exporter:node_exporter /usr/local/bin/node_exporter

        # 3. Crear Servicio Systemd para Node Exporter
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

# 2. Grupo de Auto Escalado (ASG)
resource "aws_autoscaling_group" "web_asg" {
  name_prefix         = "asg-${var.environment}-"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [var.target_group_arn]

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  force_delete              = true
  health_check_type         = "ELB" # Revisa el estado de salud a través del ELB
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
