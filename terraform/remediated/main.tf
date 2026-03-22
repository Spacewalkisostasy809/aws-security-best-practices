# remediated/main.tf
# Same resources as vulnerable/ but with security best practices applied.
# Every setting that was wrong in vulnerable/ is fixed here.
# Run: terraform -chdir=terraform/remediated apply
# Then: bash scripts/audit-iam.sh --region ap-south-1  (should show mostly PASS)

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
      Environment = "remediated"
      ManagedBy   = "terraform"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ── VPC — use a dedicated VPC, not the default ────────────────────────────────
# REMEDIATED: dedicated VPC with private subnets
# (using default VPC here for simplicity — in production use a dedicated VPC
#  with private subnets and no internet gateway for compute/DB tiers)
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
# Fixed:
#   ✓ MFA enforced via deny-without-MFA policy
#   ✓ No direct AdministratorAccess on users
#   ✓ Trust policy scoped to specific account + ExternalId
#   ✓ Strong password policy set
module "iam" {
  source = "../modules/iam"

  environment                 = "remediated"
  enforce_mfa                 = true   # MFA enforced — no finding
  attach_admin_to_user        = false  # No direct admin — no finding
  create_dangerous_trust_role = false  # Safe trust policy — no finding
}

# ── EC2 ───────────────────────────────────────────────────────────────────────
# Fixed:
#   ✓ IMDSv2 required — SSRF cannot steal credentials
#   ✓ No SSH open to world — use SSM Session Manager
#   ✓ SSM-only execution role — least privilege
#   ✓ EBS volumes encrypted
module "ec2" {
  source = "../modules/ec2"

  environment          = "remediated"
  enforce_imdsv2       = true   # IMDSv2 required — no finding
  allow_ssh_from_world = false  # No open SSH — no finding
  encrypt_ebs          = true   # Encrypted — no finding
  attach_admin_role    = false  # SSM only — no finding
  vpc_id               = data.aws_vpc.default.id
  subnet_id            = data.aws_subnets.default.ids[0]
}

# ── S3 ────────────────────────────────────────────────────────────────────────
# Fixed:
#   ✓ Block Public Access fully enabled
#   ✓ Default encryption enabled
#   ✓ Versioning enabled — ransomware protection
#   ✓ Bucket policy restricts to account + enforces HTTPS
module "s3" {
  source = "../modules/s3"

  environment         = "remediated"
  block_public_access = true   # BPA enabled — no finding
  enable_encryption   = true   # Encrypted — no finding
  enable_versioning   = true   # Versioned — no finding
  make_bucket_public  = false  # Private — no finding
  account_id          = data.aws_caller_identity.current.account_id
}

# ── RDS ───────────────────────────────────────────────────────────────────────
# Fixed:
#   ✓ Not publicly accessible
#   ✓ Storage encrypted at rest
#   ✓ 7-day automated backup retention
#   ✓ IAM database authentication enabled
#   ✓ Deletion protection enabled
module "rds" {
  source = "../modules/rds"

  environment                         = "remediated"
  publicly_accessible                 = false  # Private — no finding
  storage_encrypted                   = true   # Encrypted — no finding
  deletion_protection                 = true   # Protected — no finding
  backup_retention_period             = 7      # 7-day backups — no finding
  iam_database_authentication_enabled = true   # IAM auth — no finding
  allowed_cidr                        = "10.0.0.0/8"  # Internal only
  db_password                         = var.db_password
  vpc_id                              = data.aws_vpc.default.id
  subnet_ids                          = data.aws_subnets.default.ids
}

# ── Lambda ────────────────────────────────────────────────────────────────────
# Fixed:
#   ✓ No secrets in env vars — SECRETS_ARN references Secrets Manager
#   ✓ No public URL — use API Gateway with IAM auth
#   ✓ Minimal execution role — only CloudWatch Logs
module "lambda" {
  source = "../modules/lambda"

  environment               = "remediated"
  store_secrets_in_env_vars = false  # No secrets in env — no finding
  enable_public_url         = false  # No public URL — no finding
  use_admin_execution_role  = false  # Minimal role — no finding
  account_id                = data.aws_caller_identity.current.account_id
  region                    = data.aws_region.current.name
}

variable "db_password" {
  description = "RDS master password — use a strong unique password"
  type        = string
  sensitive   = true
}
