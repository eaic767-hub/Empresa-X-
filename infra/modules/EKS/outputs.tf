output "cluster_name" {
  value       = aws_eks_cluster.main.name
  description = "Nombre del Cluster creado"
}

output "cluster_endpoint" {
  value       = aws_eks_cluster.main.endpoint
  description = "Endpoint de la API de k8S para el cluster"
}

output "oidc_provider_arn" {
  description = "ARN del proveedor OIDC del clúster para IRSA"
  value       = aws_iam_openid_connect_provider.eks.arn
}
