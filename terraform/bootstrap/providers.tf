terraform {
  required_version = ">= 1.13.0"

  backend "s3" {
    bucket         = "enterprise-cloud-security-platform-tfstate-640168441707"
    key            = "bootstrap/terraform.tfstate"
    region         = "af-south-1"
    encrypt        = true
    dynamodb_table = "enterprise-cloud-security-platform-terraform-lock"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "bootstrap"
      ManagedBy   = "Terraform"
      Owner       = "Phelelani Sithole"
    }
  }
}