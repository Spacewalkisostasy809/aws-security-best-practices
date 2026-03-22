output "audit_command" {
  description = "Run this after apply to audit the deployed resources"
  value       = <<-EOT
    # Audit the deployed resources:
    bash scripts/audit-iam.sh --region ${var.region}
    bash scripts/audit-ec2.sh --region ${var.region}
    bash scripts/audit-network.sh --region ${var.region}
    bash scripts/audit-s3-rds.sh --region ${var.region}
  EOT
}

output "cleanup_command" {
  description = "Destroy all resources when done testing"
  value       = "terraform destroy -auto-approve"
}
