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
# SERVIDOR EC2 DE MONITOREO
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
apt-get install -y docker.io docker-compose-v2 curl
systemctl enable --now docker

# 1. Crear la estructura de carpetas necesaria para Grafana y Prometheus
mkdir -p /opt/monitoring/grafana/provisioning/datasources
mkdir -p /opt/monitoring/grafana/provisioning/dashboards
mkdir -p /opt/monitoring/data/prometheus
cd /opt/monitoring

# 2. Configurar permisos iniciales para la persistencia de Prometheus y Grafana
# UID 472 es el usuario interno predeterminado de Grafana
chown -R 472:472 /opt/monitoring/grafana
chmod -R 777 /opt/monitoring/data/prometheus

# 3. Configurar prometheus.yml base con auto-descubrimiento EC2
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
CONFIG

# 4. Inyección dinámica del job de EKS consultando la API de AWS al arrancar
echo "Descubriendo endpoint del clúster EKS para Prometheus..."
CLUSTER_NAME=$(aws eks list-clusters --region ${var.aws_region} --query 'clusters[0]' --output text 2>/dev/null || echo "")

if [ -n "$CLUSTER_NAME" ] && [ "$CLUSTER_NAME" != "None" ]; then
  EKS_ENDPOINT=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region ${var.aws_region} --query 'cluster.endpoint' --output text 2>/dev/null || echo "")
  
  if [ -n "$EKS_ENDPOINT" ] && [ "$EKS_ENDPOINT" != "None" ]; then
    CLEAN_ENDPOINT=$${EKS_ENDPOINT#https://}
    echo "¡Clúster EKS detectado! Agregando scraping dinámico para: $CLEAN_ENDPOINT"
    
    cat << 'EKSJOB' >> prometheus.yml

  - job_name: "kubernetes-cluster"
    scheme: https
    tls_config:
      insecure_skip_verify: true
    static_configs:
      - targets: ["$CLEAN_ENDPOINT"]
EKSJOB
  fi
fi

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

# 6. Configurar el Provider de Dashboards para Grafana (Ruta alineada al volumen montado)
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

# 7. Descargar automáticamente el Dashboard 1860 (Node Exporter Full)
curl -s https://grafana.com/api/dashboards/1860/revisions/37/download -o grafana/provisioning/dashboards/node_exporter.json

# 8. Inyectar automáticamente el Dashboard de Kubernetes optimizado
cat << 'K8SDASH' > grafana/provisioning/dashboards/k8s-cluster.json
{
  "annotations": { "list": [] },
  "editable": true,
  "panels": [
    {
      "datasource": { "type": "prometheus", "uid": "Prometheus" },
      "gridPos": { "h": 6, "w": 12, "x": 0, "y": 0 },
      "id": 1,
      "targets": [
        {
          "datasource": { "type": "prometheus", "uid": "Prometheus" },
          "expr": "sum(kube_node_info)",
          "refId": "A"
        }
      ],
      "title": "Total Nodes",
      "type": "stat"
    }
  ],
  "refresh": "10s",
  "title": "Kubernetes Cluster (Auto Provisioned)",
  "uid": "k8s-cluster-auto"
}
K8SDASH

# Volver a asegurar permisos correctos justo antes de levantar los contenedores
chown -R 472:472 /opt/monitoring/grafana

# 9. Crear docker-compose.yml limpio y con volúmenes corregidos
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

# 10. Levantar la pila completa de contenedores de forma automatizada
docker compose up -d
EOF
  )

  tags = {
    Name        = "monitoring-server-${var.environment}"
    Environment = var.environment
  }
}
