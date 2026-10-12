output "cluster_name" {
  value       = aws_eks_cluster.main.name
  description = "Nombre del Cluster creado"
}

output "cluster_endpoint" {
  value       = aws_eks_cluster.main.endpoint
  description = "Endpoint de la API de k8S para el cluster"
}
