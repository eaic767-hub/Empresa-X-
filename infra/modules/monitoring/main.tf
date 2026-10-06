# Security Group dedicado al servidor de monitoreo
resource "aws_security_group" "monitoring_sg" {
  name        = "monitoring-sg-${var.environment}"
  description = "Security Group de monitoreo Prometheus & Grafana"
  vpc_id      = var.vpc_id

  # Grafana UI (3000)
  ingress {
    description = "Grafana Web Dashboard"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Prometheus UI/API (9090) - Abierto para acceso directo desde la web
  ingress {
    description = "Prometheus Server UI"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Salida total para scraping de EC2s en la VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "monitoring-sg-${var.environment}"
    Environment = var.environment
  }
}

# Servidor EC2 de monitoreo
resource "aws_instance" "monitoring_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.monitoring_sg.id]
  iam_instance_profile   = var.instance_profile_name

  user_data = base64encode(<<-EOF
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y docker.io docker-compose curl
systemctl enable --now docker

# 1. Crear la estructura de carpetas necesaria para Grafana y Prometheus
mkdir -p /opt/monitoring/grafana/provisioning/datasources
mkdir -p /opt/monitoring/grafana/provisioning/dashboards
cd /opt/monitoring

# 2. Configurar prometheus.yml
cat <<CONFIG > prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node_exporter'
    ec2_sd_configs:
      - region: us-east-1
        port: 9100
    relabel_configs:
      # Filtrar por entorno (var.environment)
      - source_labels: [__meta_ec2_tag_Environment]
        regex: ${var.environment}
        action: keep

      # Conservar ÚNICAMENTE instancias en estado 'running'
      - source_labels: [__meta_ec2_instance_state]
        regex: running
        action: keep

      # Asignar la IP privada como la etiqueta 'instance' (con su puerto 9100)
      - source_labels: [__meta_ec2_private_ip]
        replacement: '$${1}:9100'
        target_label: instance
CONFIG

# 3. Auto-aprovisionar Datasource de Prometheus en Grafana
cat <<DATASOURCE > grafana/provisioning/datasources/prometheus.yml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
DATASOURCE

# 4. Configurar el Provider de Dashboards para Grafana
cat <<PROVIDER > grafana/provisioning/dashboards/dashboards.yml
apiVersion: 1
providers:
  - name: 'Default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    editable: true
    options:
      path: /etc/grafana/provisioning/dashboards
PROVIDER

# 5. Descargar automáticamente el Dashboard 1860 (Node Exporter Full)
curl -s https://grafana.com/api/dashboards/1860/revisions/37/download -o grafana/provisioning/dashboards/node_exporter.json

# 6. Crear docker-compose.yml montando las carpetas de aprovisionamiento
cat <<COMPOSE > docker-compose.yml
version: '3.8'
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: always
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: always
    ports:
      - "3000:3000"
    volumes:
      - ./grafana/provisioning:/etc/grafana/provisioning
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
COMPOSE

# 7. Levantar la pila de contenedores
docker-compose up -d
EOF
  )

  tags = {
    Name        = "monitoring-server-${var.environment}"
    Environment = var.environment
  }
}
