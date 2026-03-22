output "instance_id" {
  value = aws_instance.test_instance.id
}

output "instance_role_arn" {
  value = aws_iam_role.instance_role.arn
}

output "security_group_id" {
  value = aws_security_group.instance_sg.id
}

output "imdsv2_status" {
  value = var.enforce_imdsv2 ? "required (secure)" : "optional (VULNERABLE - IMDSv1 allowed)"
}
