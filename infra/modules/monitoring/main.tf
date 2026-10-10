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
mkdir -p /opt/monitoring/data/prometheus
cd /opt/monitoring

# 2. Configurar permisos iniciales para la persistencia de Prometheus
chmod -R 777 data/prometheus

# 3. Configurar prometheus.yml
cat <<CONFIG > prometheus.yml
global:
  scrape_interval: 5s
  evaluation_interval: 5s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node_exporter'
    ec2_sd_configs:
      - region: us-east-1
        port: 9100
    relabel_configs:
      # 1. Filtrar solo instancias del entorno actual
      - source_labels: [__meta_ec2_tag_Environment]
        regex: ${var.environment}
        action: keep

      # 2. Conservar ÚNICAMENTE instancias activas
      - source_labels: [__meta_ec2_instance_state]
        regex: running
        action: keep

      # 3. Asignar la IP privada explícitamente como la dirección de destino del scrape
      - source_labels: [__meta_ec2_private_ip]
        target_label: __address__
        replacement: '$${1}:9100'

      # 4. Mostrar la IP privada limpia como nombre de instancia
      - source_labels: [__meta_ec2_private_ip]
        target_label: instance
        replacement: '$${1}'
CONFIG

# 4. Auto-aprovisionar Datasource de Prometheus en Grafana
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

# 5. Configurar el Provider de Dashboards para Grafana
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

# 6. Descargar automáticamente el Dashboard 1860 (Node Exporter Full)
curl -s https://grafana.com/api/dashboards/1860/revisions/37/download -o grafana/provisioning/dashboards/node_exporter.json

# 7. Crear docker-compose.yml incluyendo Prometheus, Grafana y Node Exporter integrado
cat <<COMPOSE > docker-compose.yml
version: '3.8'
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: always
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=1h'
      - '--web.enable-lifecycle'
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - ./data/prometheus:/prometheus
    ports:
      - "9090:9090"

  node_exporter:
    image: prom/node-exporter:latest
    container_name: node_exporter
    restart: always
    ports:
      - "9100:9100"
    command:
      - '--path.rootfs=/host'
    volumes:
      - /:/host:ro,rslave

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

# 8. Levantar la pila completa de contenedores
docker-compose up -d
EOF
  )

  tags = {
    Name        = "monitoring-server-${var.environment}"
    Environment = var.environment
  }
}
