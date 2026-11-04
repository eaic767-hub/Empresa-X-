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
apt-get install -y docker.io docker-compose curl
systemctl enable --now docker

# 1. Crear la estructura completa de carpetas para Grafana y Prometheus
mkdir -p /opt/monitoring/grafana/provisioning/datasources
mkdir -p /opt/monitoring/grafana/provisioning/dashboards
mkdir -p /opt/monitoring/data/prometheus
cd /opt/monitoring

# 2. Configurar permisos iniciales para la persistencia de Prometheus
chmod -R 777 data/prometheus

# 3. Configurar prometheus.yml base con auto-descubrimiento EC2
cat << 'CONFIG' > prometheus.yml
global:
  scrape_interval: 5s
  evaluation_interval: 5s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node_exporter'
    ec2_sd_configs:
      - region: ${var.aws_region}
        port: 9100
    relabel_configs:
      - source_labels: [__meta_ec2_tag_Environment]
        regex: ${var.environment}
        action: keep
      - source_labels: [__meta_ec2_instance_state]
        regex: running
        action: keep
      - source_labels: [__meta_ec2_private_ip]
        regex: (.*)
        target_label: __address__
        replacement: '$1:9100'
      - source_labels: [__meta_ec2_private_ip]
        regex: (.*)
        target_label: instance
        replacement: '$1'
CONFIG

# 4. Inyección dinámica del job de EKS (Módulo 4)
CLUSTER_NAME=$(aws eks list-clusters --region ${var.aws_region} --query 'clusters[0]' --output text 2>/dev/null || echo "")

if [ -n "$CLUSTER_NAME" ] && [ "$CLUSTER_NAME" != "None" ]; then
  EKS_ENDPOINT=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region ${var.aws_region} --query 'cluster.endpoint' --output text 2>/dev/null || echo "")
  
  if [ -n "$EKS_ENDPOINT" ] && [ "$EKS_ENDPOINT" != "None" ]; then
    CLEAN_ENDPOINT=$${EKS_ENDPOINT#https://}
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

# 6. Configurar el Provider de Dashboards para Grafana apuntando a la carpeta interna
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
      path: /var/lib/grafana/dashboards
PROVIDER

# 7. Descargar automáticamente el Dashboard 1860 (Node Exporter Full)
curl -s https://grafana.com/api/dashboards/1860/revisions/37/download -o grafana/provisioning/dashboards/node_exporter.json

# 8. Inyectar automáticamente el Dashboard de Kubernetes (ID 3115 adaptado)
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

# 9. Crear docker-compose.yml montando las carpetas de aprovisionamiento en las rutas correctas de Grafana
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
      - ./grafana/provisioning/datasources:/etc/grafana/provisioning/datasources
      - ./grafana/provisioning/dashboards:/etc/grafana/provisioning/dashboards
      - ./grafana/provisioning/dashboards:/var/lib/grafana/dashboards
    environment:
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
