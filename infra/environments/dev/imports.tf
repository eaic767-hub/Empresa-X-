# 1. Rol de Scheduler (está en la raíz, en scheduler.tf)
import {
  to = aws_iam_role.scheduler_role
  id = "scheduler-asg-rds-role-dev"
}

# 2. Rol de EKS Cluster (está dentro del módulo EKS)
import {
  to = module.EKS.aws_iam_role.eks_cluster
  id = "empresa-x-eks-cluster-role-dev"
}

# 3. Rol de EC2 Backend (dentro del módulo ec2)
import {
  to = module.ec2.aws_iam_role.backend_role
  id = "ec2-backend-role-dev"
}

# 4. Política de EC2 Backend (dentro del módulo ec2)
# Nota: Para políticas IAM, Terraform suele requerir el ARN completo o el ID de la política. 
# Si el nombre único es suficiente, puedes usar el nombre o el ARN exacto de AWS.
import {
  to = module.ec2.aws_iam_policy.backend_sdk_policy
  id = "arn:aws:iam::<TU_ACCOUNT_ID>:policy/ec2-backend-sdk-policy-dev"
  # O si prefieres buscar el nombre exacto, pero el ARN es lo seguro para políticas.
}

# 5. DB Subnet Group de RDS (dentro del módulo rds)
import {
  to = module.rds_dev.aws_db_subnet_group.rds_subnet_group
  id = "dev-rds-subnet-group"
}

# 6. Secret Manager Secret de RDS (dentro del módulo rds)
import {
  to = module.rds_dev.aws_secretsmanager_secret.db_credentials
  id = "dev-mysql-db-credentials"
}

# 7. Target Group del ALB (dentro del módulo alb)
# Nota: Los Target Groups usualmente piden el ARN completo como ID.
import {
  to = module.alb.aws_lb_target_group.this
  id = "arn:aws:elasticloadbalancing:us-east-1:<TU_ACCOUNT_ID>:targetgroup/tg-dev-backend-v2/..."
}
