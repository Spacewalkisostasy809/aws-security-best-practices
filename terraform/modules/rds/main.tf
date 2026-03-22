locals {
  prefix = "audit-test-${var.environment}"
}

# ── Security Group ─────────────────────────────────────────────────────────────
# VULNERABLE:  MySQL/Postgres port open to 0.0.0.0/0
# REMEDIATED:  port only open to specific CIDR (internal network)
resource "aws_security_group" "rds_sg" {
  name        = "${local.prefix}-rds-sg"
  description = "RDS audit test - ${var.environment}"
  vpc_id      = var.vpc_id

  ingress {
    description = var.allowed_cidr == "0.0.0.0/0" ? "MySQL from anywhere — INSECURE" : "MySQL from internal network"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  tags = {
    Purpose = "audit-test"
    Risk    = var.allowed_cidr == "0.0.0.0/0" ? "CRITICAL - DB open to internet" : "LOW"
  }
}

# ── DB Subnet Group ────────────────────────────────────────────────────────────
resource "aws_db_subnet_group" "test_db" {
  name        = "${local.prefix}-db-subnet-group"
  description = "Audit test subnet group"
  subnet_ids  = var.subnet_ids

  tags = {
    Purpose = "audit-test"
  }
}

# ── RDS Instance ───────────────────────────────────────────────────────────────
# VULNERABLE:  public, unencrypted, no backups, no IAM auth, no deletion protection
# REMEDIATED:  private, encrypted, 7-day backups, IAM auth, deletion protection
resource "aws_db_instance" "test_db" {
  identifier = "${local.prefix}-db"

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = "audittest"
  username = "admin"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.test_db.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  # VULNERABLE: true  → directly reachable from internet
  # REMEDIATED: false → private subnet only
  publicly_accessible = var.publicly_accessible

  # VULNERABLE: false → data readable if storage media compromised
  # REMEDIATED: true  → data encrypted at rest with KMS
  storage_encrypted = var.storage_encrypted

  # VULNERABLE: 0  → no automated backups, ransomware = permanent data loss
  # REMEDIATED: 7  → 7 days of point-in-time recovery
  backup_retention_period = var.backup_retention_period

  # VULNERABLE: false → static master password, never rotated
  # REMEDIATED: true  → short-lived IAM tokens instead of passwords
  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  # VULNERABLE: false → can be deleted with one API call
  # REMEDIATED: true  → requires explicit disable before deletion
  deletion_protection = var.deletion_protection

  # Always skip final snapshot in test environments
  skip_final_snapshot = true

  tags = {
    Purpose = "audit-test"
    Risk = join(", ", compact([
      var.publicly_accessible ? "public-access" : "",
      !var.storage_encrypted ? "unencrypted" : "",
      var.backup_retention_period == 0 ? "no-backups" : "",
      !var.iam_database_authentication_enabled ? "static-password" : "",
      !var.deletion_protection ? "no-deletion-protection" : "",
    ]))
  }
}
