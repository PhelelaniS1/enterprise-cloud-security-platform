#########################################
# Platform Monitoring Log Group
#########################################

resource "aws_cloudwatch_log_group" "platform" {
  name              = "/aws/eks/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.project_name}-${var.environment}-logs"
  }
}

#########################################
# EKS Control Plane Log Group
#########################################

resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = var.eks_cluster_log_group_name
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.project_name}-${var.environment}-eks-cluster-logs"
  }
}
