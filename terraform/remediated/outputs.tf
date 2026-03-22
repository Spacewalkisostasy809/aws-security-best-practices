output "summary" {
  description = "Summary of remediated resources"
  value       = <<-EOT

    ╔══════════════════════════════════════════════════════════╗
    ║   REMEDIATED ENVIRONMENT DEPLOYED                       ║
    ║   Run audit scripts to verify findings are resolved:    ║
    ╚══════════════════════════════════════════════════════════╝

    bash scripts/audit-iam.sh     --region ap-south-1
    bash scripts/audit-ec2.sh     --region ap-south-1
    bash scripts/audit-network.sh --region ap-south-1
    bash scripts/audit-s3-rds.sh  --region ap-south-1

    Expected results:
      IAM     — MFA enforced, no direct admin, safe trust policy, password policy set
      EC2     — IMDSv2 required, no open SSH, SSM role, encrypted EBS
      S3      — private bucket, encrypted, versioned, HTTPS-only policy
      RDS     — private, encrypted, 7-day backups, IAM auth, deletion protection
      Lambda  — no secrets in env, no public URL, minimal execution role

    IMPORTANT: Destroy when done testing:
      terraform destroy -auto-approve
  EOT
}

output "s3_bucket" {
  value = module.s3.bucket_name
}

output "rds_endpoint" {
  value     = module.rds.db_endpoint
  sensitive = false
}

output "lambda_function" {
  value = module.lambda.function_name
}
