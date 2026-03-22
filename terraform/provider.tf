terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment and configure to use remote state
  # backend "s3" {
  #   bucket         = "your-tfstate-bucket"
  #   key            = "aws-security-best-practices/terraform.tfstate"
  #   region         = "ap-south-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "aws-security-best-practices"
      ManagedBy   = "terraform"
      Repository  = "github.com/sharanch/aws-security-best-practices"
    }
  }
}
