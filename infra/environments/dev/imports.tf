# 1. Rol de Scheduler
import {
  to = aws_iam_role.scheduler_role
  id = "scheduler-asg-rds-role-dev"
}

# 2. Rol de EKS Cluster
import {
  to = module.EKS.aws_iam_role.eks_cluster
  id = "empresa-x-eks-cluster-role-dev"
}

# 3. Rol de EC2 Backend
import {
  to = module.ec2.aws_iam_role.backend_role
  id = "ec2-backend-role-dev"
}

# 4. Política de EC2 Backend
import {
  to = module.ec2.aws_iam_policy.backend_sdk_policy
  id = "arn:aws:iam::798474696671:policy/ec2-backend-sdk-policy-dev"
}

# 5. DB Subnet Group de RDS
import {
  to = module.rds_dev.aws_db_subnet_group.rds_subnet_group
  id = "dev-rds-subnet-group"
}

# 6. Secret Manager Secret de RDS
import {
  to = module.rds_dev.aws_secretsmanager_secret.db_credentials
  id = "arn:aws:secretsmanager:us-east-1:798474696671:secret:dev-mysql-db-credentials-0EF3QD"
}

# 8. Target Group del ALB (faltaba en el import anterior)
import {
  to = module.alb.aws_lb_target_group.this
  id = "arn:aws:elasticloadbalancing:us-east-1:798474696671:targetgroup/tg-dev-backend-v2/c4346ccf4a4421f1"
}

# 9. Instance Profile de EC2
import {
  to = module.ec2.aws_iam_instance_profile.backend_profile
  id = "ec2-backend-profile-dev"
}
