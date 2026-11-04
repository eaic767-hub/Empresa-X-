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
# SERVIDOR EC2 DE MONITOREO (ESTANDARIZADO Y AUTOMATIZADO)
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
apt-get install -y docker.io docker-compose-v2 curl wget awscli

# 1. Instalar kubectl para interactuar con EKS de forma automatizada
curl -LO "https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# 2. Instalar y configurar Node Exporter en la interfaz IPv4 local (127.0.0.1:9100)
NODE_EXPORTER_VERSION="1.7.0"
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v$${NODE_EXPORTER_VERSION}/node_exporter-$${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar xvf node_exporter-$${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
cp node_exporter-$${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
chmod +x /usr/local/bin/node_exporter

cat << 'SERVICE' > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=nobody
ExecStart=/usr/local/bin/node_exporter --web.listen-address=127.0.0.1:9100

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable --now node_exporter

# 3. Conectar al cluster EKS y desplegar kube-state-metrics automáticamente
EKS_CLUSTER_NAME=$(aws eks list-clusters --region us-east-1 --query "clusters[0]" --output text)
if [ "$EKS_CLUSTER_NAME" != "None" ] && [ -n "$EKS_CLUSTER_NAME" ]; then
    aws eks update-kubeconfig --region us-east-1 --name "$EKS_CLUSTER_NAME"
    wget https://raw.githubusercontent.com/kubernetes/kube-state-metrics/v2.10.1/examples/standard/deploy.yaml -O kube-state-metrics.yaml
    kubectl apply -f kube-state-metrics.yaml
fi

# 4. Crear estructura de carpetas para Prometheus y Grafana
mkdir -p /opt/monitoring/grafana/provisioning/datasources
mkdir -p /opt/monitoring/grafana/provisioning/dashboards
mkdir -p /opt/monitoring/data/prometheus
cd /opt/monitoring

chown -R 472:472 /opt/monitoring/grafana
chmod -R 777 /opt/monitoring/data/prometheus

# 5. Configurar prometheus.yml limpio con targets estables
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

# 6. Auto-aprovisionar Datasource de Prometheus en Grafana
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

# 7. Configurar Provider de Dashboards para Grafana
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

# 8. Descargar automáticamente los Dashboards oficiales (Node Exporter 1860 y Kubernetes 3115)
curl -s https://grafana.com/api/dashboards/1860/revisions/37/download -o grafana/provisioning/dashboards/node_exporter.json
curl -s https://grafana.com/api/dashboards/3115/revisions/3/download -o grafana/provisioning/dashboards/kubernetes.json

chown -R 472:472 /opt/monitoring/grafana

# 9. Crear docker-compose.yml y levantar la pila de contenedores
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

docker compose up -d
EOF
  )

  tags = {
    Name        = "monitoring-server-${var.environment}"
    Environment = var.environment
  }
}
