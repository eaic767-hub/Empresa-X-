#------------------------------------------------------------------------------
# IAM ROLE + INSTANCE PROFILE PARA EL SERVIDOR DE MONITOREO
#------------------------------------------------------------------------------

resource "aws_iam_role" "monitoring_role" {
  name = "monitoring-server-role-${var.environment}"

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

resource "aws_iam_role_policy_attachment" "monitoring_ssm" {
  role       = aws_iam_role.monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "monitoring_eks_read" {
  role       = aws_iam_role.monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_instance_profile" "monitoring_profile" {
  name = "monitoring-server-profile-${var.environment}"
  role = aws_iam_role.monitoring_role.name
}

#------------------------------------------------------------------------------
# SECURITY GROUP DEDICADO AL SERVIDOR DE MONITOREO
#------------------------------------------------------------------------------
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

  # Prometheus UI/API (9090)
  ingress {
    description = "Prometheus Server UI"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Salida total para scraping"
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

#------------------------------------------------------------------------------
# SERVIDOR EC2 DE MONITOREO (TOTALMENTE AUTOMATIZADO - K8S + EC2)
#------------------------------------------------------------------------------
resource "aws_instance" "monitoring_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.monitoring_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.monitoring_profile.name

  user_data_replace_on_change = true

  user_data_base64 = base64encode(<<-EOF
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y docker.io docker-compose-v2 curl wget

# 1. Instalar y configurar Node Exporter de forma nativa como servicio del sistema
NODE_EXPORTER_VERSION="1.7.0"
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v$${NODE_EXPORTER_VERSION}/node_exporter-$${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar xvf node_exporter-$${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
cp node_exporter-$${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
chmod +x /usr/local/bin/node_exporter

# Crear servicio systemd para Node Exporter
cat << 'SERVICE' > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=nobody
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable --now node_exporter

# 2. Crear la estructura de carpetas necesaria para Prometheus y Grafana
mkdir -p /opt/monitoring/grafana/provisioning/datasources
mkdir -p /opt/monitoring/grafana/provisioning/dashboards
mkdir -p /opt/monitoring/data/prometheus
cd /opt/monitoring

# 3. Aplicar permisos críticos (UID 472 para Grafana y 777 para Prometheus)
chown -R 472:472 /opt/monitoring/grafana
chmod -R 777 /opt/monitoring/data/prometheus

# 4. Configurar prometheus.yml con targets locales y soporte para Kubernetes (Kube-State-Metrics)
cat << 'CONFIG' > prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']

  - job_name: 'kube-state-metrics'
    static_configs:
      - targets: ['kube-state-metrics.kube-system.svc:8080']
CONFIG

# 5. Auto-aprovisionar Datasource de Prometheus en Grafana
cat << 'DATASOURCE' > grafana/provisioning/datasources/prometheus.yml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
DATASOURCE

# 6. Configurar el Provider de Dashboards para Grafana
cat << 'PROVIDER' > grafana/provisioning/dashboards/dashboards.yml
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

# 7. Descargar automáticamente los Dashboards oficiales: Node Exporter (1860) y Kubernetes (3115)
curl -s https://grafana.com/api/dashboards/1860/revisions/37/download -o grafana/provisioning/dashboards/node_exporter.json
curl -s https://grafana.com/api/dashboards/3115/revisions/3/download -o grafana/provisioning/dashboards/kubernetes.json

# Asegurar permisos finales en Grafana antes de levantar contenedores
chown -R 472:472 /opt/monitoring/grafana

# 8. Crear docker-compose.yml y levantar la pila
cat << 'COMPOSE' > docker-compose.yml
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

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: always
    ports:
      - "3000:3000"
    volumes:
      - ./grafana/provisioning:/etc/grafana/provisioning
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
COMPOSE

systemctl enable --now docker
docker compose up -d
EOF
  )

  tags = {
    Name        = "monitoring-server-${var.environment}"
    Environment = var.environment
  }
}
