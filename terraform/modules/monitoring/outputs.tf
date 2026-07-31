output "log_group_name" {
  description = "Platform CloudWatch log group name"
  value       = aws_cloudwatch_log_group.platform.name
}

output "log_group_arn" {
  description = "Platform CloudWatch log group ARN"
  value       = aws_cloudwatch_log_group.platform.arn
}

output "eks_cluster_log_group_name" {
  description = "EKS control plane CloudWatch log group name"
  value       = aws_cloudwatch_log_group.eks_cluster.name
}

output "eks_cluster_log_group_arn" {
  description = "EKS control plane CloudWatch log group ARN"
  value       = aws_cloudwatch_log_group.eks_cluster.arn
}
