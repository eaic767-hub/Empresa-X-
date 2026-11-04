output "grafana_service_name" {
  description = "Nombre del servicio de Grafana en el clúster"
  value       = "prometheus-stack-grafana"
}

output "monitoring_namespace" {
  description = "Namespace donde corre el stack de monitoreo"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "grafana_access_instructions" {
  description = "Instrucciones para acceder a Grafana mediante port-forwarding local"
  value       = "Ejecuta: kubectl port-forward svc/prometheus-stack-grafana 3000:3000 -n monitoring (Usuario: admin / Password: admin)"
}
