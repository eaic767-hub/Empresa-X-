output "grafana_service_name" {
  description = "Nombre del servicio de Grafana en el clúster"
  value       = "prometheus-stack-grafana"
}

output "monitoring_namespace" {
  description = "Namespace donde corre el stack de monitoreo"
  value       = "monitoring"
}

output "grafana_access_instructions" {
  description = "Instrucciones para acceder a Grafana mediante port-forwarding local"
  value       = "Ejecuta: kubectl port-forward svc/prometheus-stack-grafana 3000:3000 -n monitoring (Usuario: admin / Password: admin)"
}

output "grafana_url" {
  description = "Endpoint interno del servicio de Grafana en Kubernetes"
  value       = "http://prometheus-grafana.monitoring.svc.cluster.local:80"
}

output "prometheus_url" {
  description = "Endpoint interno del servicio de Prometheus en Kubernetes"
  value       = "http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090"
}
