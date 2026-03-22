locals {
  prefix = "audit-test-${var.environment}"
}

# ── S3 Bucket ─────────────────────────────────────────────────────────────────
resource "aws_s3_bucket" "test_bucket" {
  # Unique suffix to avoid global name collisions
  bucket        = "${local.prefix}-bucket-${var.account_id}"
  force_destroy = true # Allow terraform destroy to empty the bucket

  tags = {
    Purpose = "audit-test"
    Risk    = var.make_bucket_public ? "CRITICAL - public access" : "LOW"
  }
}

# ── Block Public Access ────────────────────────────────────────────────────────
# VULNERABLE:  all settings false — bucket can be made public
# REMEDIATED:  all settings true — no public access possible
resource "aws_s3_bucket_public_access_block" "test_bucket" {
  bucket = aws_s3_bucket.test_bucket.id

  block_public_acls       = var.block_public_access
  ignore_public_acls      = var.block_public_access
  block_public_policy     = var.block_public_access
  restrict_public_buckets = var.block_public_access
}

# ── Encryption ────────────────────────────────────────────────────────────────
# VULNERABLE:  no default encryption
# REMEDIATED:  SSE-S3 encryption by default (or SSE-KMS for sensitive data)
resource "aws_s3_bucket_server_side_encryption_configuration" "test_bucket" {
  count  = var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.test_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# ── Versioning ────────────────────────────────────────────────────────────────
# VULNERABLE:  versioning disabled — ransomware deletes are permanent
# REMEDIATED:  versioning enabled — objects recoverable after delete
resource "aws_s3_bucket_versioning" "test_bucket" {
  bucket = aws_s3_bucket.test_bucket.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# ── Bucket Policy ─────────────────────────────────────────────────────────────
# VULNERABLE:  Principal: * — anyone on the internet can read objects
# REMEDIATED:  restricted to current account only, HTTPS enforced
data "aws_iam_policy_document" "public_policy" {
  statement {
    sid    = "PublicRead"
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.test_bucket.arn}/*"]
  }
}

data "aws_iam_policy_document" "safe_policy" {
  # Deny all non-HTTPS access
  statement {
    sid    = "DenyHTTP"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:*"]
    resources = [
      aws_s3_bucket.test_bucket.arn,
      "${aws_s3_bucket.test_bucket.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  # Deny cross-account access
  statement {
    sid    = "DenyCrossAccount"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:*"]
    resources = [
      aws_s3_bucket.test_bucket.arn,
      "${aws_s3_bucket.test_bucket.arn}/*",
    ]

    condition {
      test     = "StringNotEquals"
      variable = "aws:PrincipalAccount"
      values   = [var.account_id]
    }
  }
}

resource "aws_s3_bucket_policy" "test_bucket" {
  bucket = aws_s3_bucket.test_bucket.id
  policy = var.make_bucket_public ? data.aws_iam_policy_document.public_policy.json : data.aws_iam_policy_document.safe_policy.json

  depends_on = [aws_s3_bucket_public_access_block.test_bucket]
}

# ── Lifecycle — expire old versions ───────────────────────────────────────────
# REMEDIATED only — keep object history manageable
resource "aws_s3_bucket_lifecycle_configuration" "test_bucket" {
  count  = var.enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.test_bucket.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
