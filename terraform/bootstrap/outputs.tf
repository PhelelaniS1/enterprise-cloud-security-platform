output "terraform_state_bucket" {
  description = "Terraform state bucket name."
  value       = aws_s3_bucket.terraform_state.bucket
}

output "terraform_lock_table" {
  description = "Terraform state lock table."
  value       = aws_dynamodb_table.terraform_lock.name
}

output "aws_region" {
  description = "AWS deployment region."
  value       = var.aws_region
}