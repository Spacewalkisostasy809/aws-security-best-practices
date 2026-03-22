# vulnerable/main.tf
# Provisions deliberately misconfigured resources to trigger all audit script findings.
# Run: terraform -chdir=terraform/vulnerable apply
# Then: bash scripts/audit-iam.sh --region ap-south-1

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"

  default_tags {
    tags = {
      Project     = "aws-security-best-practices"
      Environment = "vulnerable"
      ManagedBy   = "terraform"
      Warning     = "deliberately-misconfigured-for-audit-testing"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ── Default VPC (already exists — just reference it) ──────────────────────────
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ── IAM ───────────────────────────────────────────────────────────────────────
# Triggers:
#   [CRITICAL] User has access key, no MFA
#   [CRITICAL] User has AdministratorAccess attached directly
#   [CRITICAL] Role has Principal: * in trust policy
#   [CRITICAL] No account password policy
module "iam" {
  source = "../modules/iam"

  environment                  = "vulnerable"
  enforce_mfa                  = false  # No MFA policy — finding fires
  attach_admin_to_user         = true   # Direct admin access — finding fires
  create_dangerous_trust_role  = true   # Principal: * — finding fires
}

# ── EC2 ───────────────────────────────────────────────────────────────────────
# Triggers:
#   [CRITICAL] IMDSv1 enabled — SSRF credential theft vector
#   [CRITICAL] SSH open to 0.0.0.0/0
#   [CRITICAL] Instance has AdministratorAccess role
#   [WARNING]  EBS volume not encrypted
module "ec2" {
  source = "../modules/ec2"

  environment          = "vulnerable"
  enforce_imdsv2       = false  # IMDSv1 allowed — finding fires
  allow_ssh_from_world = true   # SSH open to world — finding fires
  encrypt_ebs          = false  # No encryption — finding fires
  attach_admin_role    = true   # Admin role — finding fires
  vpc_id               = data.aws_vpc.default.id
  subnet_id            = data.aws_subnets.default.ids[0]
}

# ── S3 ────────────────────────────────────────────────────────────────────────
# Triggers:
#   [CRITICAL] Bucket is PUBLIC via Principal: * policy
#   [WARNING]  No default encryption
#   [WARNING]  Versioning disabled
#   [WARNING]  No access logging
module "s3" {
  source = "../modules/s3"

  environment         = "vulnerable"
  block_public_access = false  # Public access allowed — finding fires
  enable_encryption   = false  # No encryption — finding fires
  enable_versioning   = false  # No versioning — finding fires
  make_bucket_public  = true   # Principal: * policy — finding fires
  account_id          = data.aws_caller_identity.current.account_id
}

# ── RDS ───────────────────────────────────────────────────────────────────────
# Triggers:
#   [CRITICAL] RDS publicly accessible
#   [CRITICAL] RDS not encrypted at rest
#   [CRITICAL] Automated backups disabled
#   [WARNING]  IAM database auth disabled
#   [WARNING]  Deletion protection disabled
module "rds" {
  source = "../modules/rds"

  environment                         = "vulnerable"
  publicly_accessible                 = true   # Public — finding fires
  storage_encrypted                   = false  # Unencrypted — finding fires
  deletion_protection                 = false  # No deletion protection — finding fires
  backup_retention_period             = 0      # No backups — finding fires
  iam_database_authentication_enabled = false  # Static password — finding fires
  allowed_cidr                        = "0.0.0.0/0"  # DB port open to internet
  db_password                         = var.db_password
  vpc_id                              = data.aws_vpc.default.id
  subnet_ids                          = data.aws_subnets.default.ids
}

# ── Lambda ────────────────────────────────────────────────────────────────────
# Triggers:
#   [CRITICAL] Lambda has public URL with AuthType NONE
#   [WARNING]  Secrets in environment variables
#   [CRITICAL] Lambda execution role has AdministratorAccess
module "lambda" {
  source = "../modules/lambda"

  environment               = "vulnerable"
  store_secrets_in_env_vars = true   # Secrets in env vars — finding fires
  enable_public_url         = true   # Public URL — finding fires
  use_admin_execution_role  = true   # Admin role — finding fires
  account_id                = data.aws_caller_identity.current.account_id
  region                    = data.aws_region.current.name
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
  default     = "VulnerablePassword123!"
}
