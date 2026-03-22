locals {
  prefix = "audit-test-${var.environment}"
}

# ── Execution Role ─────────────────────────────────────────────────────────────
# VULNERABLE:  AdministratorAccess — any code path has full AWS access
# REMEDIATED:  minimal permissions — only what this function actually needs
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "${local.prefix}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = {
    Purpose = "audit-test"
    Risk    = var.use_admin_execution_role ? "CRITICAL - AdministratorAccess" : "LOW - minimal permissions"
  }
}

resource "aws_iam_role_policy_attachment" "admin_policy" {
  # VULNERABLE: full account access from Lambda
  count      = var.use_admin_execution_role ? 1 : 0
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  # REMEDIATED: only CloudWatch Logs — the minimum needed
  count      = var.use_admin_execution_role ? 0 : 1
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ── Lambda Function Code ───────────────────────────────────────────────────────
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_function.zip"

  source {
    content  = <<-EOF
      def handler(event, context):
          return {"statusCode": 200, "body": "audit-test-${var.environment}"}
    EOF
    filename = "index.py"
  }
}

# ── Lambda Function ────────────────────────────────────────────────────────────
resource "aws_lambda_function" "test_function" {
  function_name    = "${local.prefix}-function"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  # VULNERABLE:  secrets stored as plaintext environment variables
  # REMEDIATED:  no secrets in env vars — fetch from Secrets Manager at runtime
  environment {
    variables = var.store_secrets_in_env_vars ? {
      DB_PASSWORD      = "super-secret-prod-password"
      API_KEY          = "sk-live-abc123xyz"
      STRIPE_SECRET    = "sk_live_xxxxxxxx"
      APP_ENV          = "production"
    } : {
      APP_ENV          = "production"
      SECRETS_ARN      = "arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:prod/app/secrets"
    }
  }

  tags = {
    Purpose = "audit-test"
    Risk = join(", ", compact([
      var.store_secrets_in_env_vars ? "secrets-in-env-vars" : "",
      var.enable_public_url ? "public-url" : "",
      var.use_admin_execution_role ? "admin-execution-role" : "",
    ]))
  }
}

# ── Lambda URL ────────────────────────────────────────────────────────────────
# VULNERABLE:  AuthType NONE — anyone on the internet can invoke this function
# REMEDIATED:  not created (use API Gateway with IAM auth instead)
resource "aws_lambda_function_url" "public_url" {
  count              = var.enable_public_url ? 1 : 0
  function_name      = aws_lambda_function.test_function.function_name
  authorization_type = "NONE" # No auth — public invocation
}
