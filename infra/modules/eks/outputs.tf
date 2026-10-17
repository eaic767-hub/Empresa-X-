output "cluster_name" {
  value       = aws_eks_cluster.main.name
  description = "Nombre del Cluster creado"
}

output "cluster_endpoint" {
  value       = aws_eks_cluster.main.endpoint
  description = "Endpoint de la API de k8S para el cluster"
}

output "node_group_id" {
  description = "ID del EKS Node Group"
  value       = aws_eks_node_group.main.id
}

output "node_group_status" {
  description = "Estado actual del Node Group"
  value       = aws_eks_node_group.main.status
}
