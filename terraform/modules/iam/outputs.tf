output "test_user_name" {
  value = aws_iam_user.test_user.name
}

output "access_key_id" {
  description = "Access key ID (vulnerable only — never use static keys in production)"
  value       = length(aws_iam_access_key.test_user_key) > 0 ? aws_iam_access_key.test_user_key[0].id : "none - SSO used instead"
  sensitive   = false
}

output "access_key_secret" {
  description = "Access key secret (vulnerable only)"
  value       = length(aws_iam_access_key.test_user_key) > 0 ? aws_iam_access_key.test_user_key[0].secret : "none"
  sensitive   = true
}

output "dangerous_trust_role_arn" {
  value = length(aws_iam_role.dangerous_trust_role) > 0 ? aws_iam_role.dangerous_trust_role[0].arn : "not created"
}
