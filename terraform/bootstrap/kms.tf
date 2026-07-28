resource "aws_kms_key" "terraform_state" {
  description             = "KMS key for Terraform remote state"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "Terraform State KMS Key"
  }
}

resource "aws_kms_alias" "terraform_state" {
  name          = "alias/terraform-state"
  target_key_id = aws_kms_key.terraform_state.key_id
}