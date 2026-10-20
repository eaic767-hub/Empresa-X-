# Rol IAM para el Cluster EKS
resource "aws_iam_role" "eks_cluster" {
  name = var.resource_prefix != "" ? "empresa-x-eks-cluster-role-${var.resource_prefix}-${var.environment}" : "empresa-x-eks-cluster-role-${var.environment}"

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

# El Cluster EKS administrado por AWS
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

# --- CONFIGURACIÓN DE NODOS WORKERS PARA EKS ---

# 1. Rol IAM para los Nodos Worker
resource "aws_iam_role" "eks_nodes" {
  name = var.resource_prefix != "" ? "empresa-x-eks-node-role-${var.resource_prefix}-${var.environment}" : "empresa-x-eks-node-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "nodes_amazon_eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_amazon_eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_amazon_ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

# 2. Grupo de Nodos Administrados (EC2 Workers)
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = var.resource_prefix != "" ? "empresa-x-nodegroup-${var.resource_prefix}-${var.environment}" : "empresa-x-nodegroup-${var.environment}"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = 3
    max_size     = 4
    min_size     = 1
  }

  instance_types = [var.instance_type] # Usará t3.micro según tus variables

  depends_on = [
    aws_iam_role_policy_attachment.nodes_amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.nodes_amazon_eks_cni_policy,
    aws_iam_role_policy_attachment.nodes_amazon_ec2_container_registry_read_only,
  ]
}

#-- CONFIGURACIÓN DE EBS CSI DRIVER (ALMACENAMIENTO PERSISTENTE PARA PODS) ---
#1. Obtener el proveedor OIDC del CLuster EKS para autenticación segura (IRSA)
data "aws_iam_openid_connect_provider" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

#2. Rol IAM para el EBS CSI Driver Controler (licencias para crear y destruir EBS CSI Driver)
resource "aws_iam_role" "ebs_csi_controller" {
  name = var.resource_prefix != "" ? "empresa-x-eks-ebs-csi-role-${var.resource_prefix}-${var.environment}" : "empresa-x-eks-ebs-csi-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = data.aws_iam_openid_connect_provider.eks.arn
      }
      Condition = {
        StringEquals = {
          "${replace(data.aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          "${replace(data.aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

#3. Adjuntar la política oficial de AWS para el manejo de EBS
resource "aws_iam_role_policy_attachment" "ebs_csi_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_controller.name
}

#4. Add-on de EKS para instalar el EBS CSI Driver
resource "aws_eks_addon" "ebs_csi" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "aws-ebs-csi-driver"
  service_account_role_arn    = aws_iam_role.ebs_csi_controller.arn
  resolve_conflicts_on_create = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.ebs_csi_policy
  ]
}
