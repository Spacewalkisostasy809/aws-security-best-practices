output "summary" {
  description = "Summary of misconfigured resources and expected findings"
  value       = <<-EOT

    ╔══════════════════════════════════════════════════════════╗
    ║   VULNERABLE ENVIRONMENT DEPLOYED                       ║
    ║   Run audit scripts to see all findings:                ║
    ╚══════════════════════════════════════════════════════════╝

    bash scripts/audit-iam.sh     --region ap-south-1
    bash scripts/audit-ec2.sh     --region ap-south-1
    bash scripts/audit-network.sh --region ap-south-1
    bash scripts/audit-s3-rds.sh  --region ap-south-1

    Expected findings:
      IAM     — no MFA, admin user, dangerous trust role, no password policy
      EC2     — IMDSv1, open SSH, admin role, unencrypted EBS
      S3      — public bucket, no encryption, no versioning
      RDS     — public, unencrypted, no backups, static password
      Lambda  — secrets in env vars, public URL, admin execution role

    IMPORTANT: Destroy when done testing:
      terraform destroy -auto-approve
  EOT
}

output "s3_bucket" {
  value = module.s3.bucket_name
}

output "rds_endpoint" {
  value = module.rds.db_endpoint
}

output "lambda_public_url" {
  value = module.lambda.public_url
}

output "iam_dangerous_role" {
  value = module.iam.dangerous_trust_role_arn
}
