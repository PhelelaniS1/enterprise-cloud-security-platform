variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log retention period"
  type        = number
  default     = 30
}

variable "eks_cluster_log_group_name" {
  description = "EKS control plane CloudWatch log group"
  type        = string
}
