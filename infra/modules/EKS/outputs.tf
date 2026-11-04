output "cluster_name" {
  value       = aws_eks_cluster.main.name
  description = "Nombre del Cluster creado"
}

output "cluster_endpoint" {
  value       = aws_eks_cluster.main.endpoint
  description = "Endpoint de la API de k8S para el cluster"
}

output "cluster_certificate_authority_data" {
  value       = aws_eks_cluster.main.certificate_authority[0].data
  description = "Datos del certificado CA del clúster EKS"
}

output "oidc_issuer_url" {
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
  description = "URL del emisor OIDC del clúster EKS"
}

output "oidc_provider_arn" {
  value       = aws_iam_openid_connect_provider.eks.arn
  description = "ARN del proveedor OIDC del clúster para IRSA"
}
