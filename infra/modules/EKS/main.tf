#Rol IAM para el Cluster EKS
resource "aws_iam_role" "eks_cluster" {
  name = "empresa-x-eks-cluster-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

#El Cluster EKS administrado por AWS

resource "aws_eks_cluster" "main" {
  name     = var.resource_prefix != "" ? "empresa-x-cluster-${var.resource_prefix}-${var.environment}" : "empresa-x-cluster-${var.environment}"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = var.subnet_ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}
