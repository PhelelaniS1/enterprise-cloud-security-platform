output "security_group_id" {
  description = "Platform security group ID"
  value       = aws_security_group.platform.id
}

output "security_group_arn" {
  description = "Platform security group ARN"
  value       = aws_security_group.platform.arn
}
