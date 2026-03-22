locals {
  prefix = "audit-test-${var.environment}"
}

# ── User with no MFA, active access key ───────────────────────────────────────
# VULNERABLE:  created with an access key, no MFA enforced
# REMEDIATED:  deny-without-MFA policy attached, access key not created
resource "aws_iam_user" "test_user" {
  name = "${local.prefix}-user"

  tags = {
    Purpose = "audit-test"
    Risk    = var.environment == "vulnerable" ? "HIGH - no MFA" : "LOW - MFA enforced"
  }
}

resource "aws_iam_access_key" "test_user_key" {
  # VULNERABLE: create a static access key (never expires)
  # REMEDIATED: no static key — use SSO instead
  count = var.environment == "vulnerable" ? 1 : 0
  user  = aws_iam_user.test_user.name
}

# MFA enforcement policy (only applied in remediated)
data "aws_iam_policy_document" "deny_without_mfa" {
  statement {
    sid    = "DenyWithoutMFA"
    effect = "Deny"

    not_actions = [
      "iam:CreateVirtualMFADevice",
      "iam:EnableMFADevice",
      "sts:GetSessionToken",
    ]

    resources = ["*"]

    condition {
      test     = "BoolIfExists"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["false"]
    }
  }
}

resource "aws_iam_user_policy" "deny_without_mfa" {
  count  = var.enforce_mfa ? 1 : 0
  name   = "DenyWithoutMFA"
  user   = aws_iam_user.test_user.name
  policy = data.aws_iam_policy_document.deny_without_mfa.json
}

# ── User with AdministratorAccess attached directly ───────────────────────────
# VULNERABLE:  AdministratorAccess on a user (never do this)
# REMEDIATED:  not created — admins use SSO with permission sets instead
resource "aws_iam_user" "admin_user" {
  count = var.attach_admin_to_user ? 1 : 0
  name  = "${local.prefix}-admin-user"

  tags = {
    Purpose = "audit-test"
    Risk    = "HIGH - direct admin access"
  }
}

resource "aws_iam_user_policy_attachment" "admin_user_policy" {
  count      = var.attach_admin_to_user ? 1 : 0
  user       = aws_iam_user.admin_user[0].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# ── Role with Principal: * in trust policy ────────────────────────────────────
# VULNERABLE:  any AWS account can assume this role (wildcard principal)
# REMEDIATED:  trust policy scoped to specific account + ExternalId condition
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "dangerous_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["*"] # Any AWS account — dangerous
    }
  }
}

data "aws_iam_policy_document" "safe_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = ["unique-external-id-${data.aws_caller_identity.current.account_id}"]
    }
  }
}

resource "aws_iam_role" "dangerous_trust_role" {
  count = var.create_dangerous_trust_role ? 1 : 0
  name  = "${local.prefix}-dangerous-trust-role"

  # VULNERABLE: Principal: * — any AWS account can assume this
  assume_role_policy = data.aws_iam_policy_document.dangerous_trust.json

  tags = {
    Purpose = "audit-test"
    Risk    = "CRITICAL - Principal wildcard"
  }
}

resource "aws_iam_role" "safe_trust_role" {
  count = var.create_dangerous_trust_role ? 0 : 1
  name  = "${local.prefix}-safe-trust-role"

  # REMEDIATED: specific account + ExternalId condition
  assume_role_policy = data.aws_iam_policy_document.safe_trust.json

  tags = {
    Purpose = "audit-test"
    Risk    = "LOW - scoped trust policy"
  }
}

# ── Password policy ───────────────────────────────────────────────────────────
# VULNERABLE:  no password policy set
# REMEDIATED:  strong password policy enforced
resource "aws_iam_account_password_policy" "password_policy" {
  count = var.environment == "remediated" ? 1 : 0

  minimum_password_length        = 14
  require_uppercase_characters   = true
  require_lowercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  password_reuse_prevention      = 5
  max_password_age               = 90
}
