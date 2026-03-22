output "function_name" {
  value = aws_lambda_function.test_function.function_name
}

output "function_arn" {
  value = aws_lambda_function.test_function.arn
}

output "public_url" {
  description = "Public Lambda URL (vulnerable only)"
  value       = length(aws_lambda_function_url.public_url) > 0 ? aws_lambda_function_url.public_url[0].function_url : "none - no public URL"
}

output "execution_role_arn" {
  value = aws_iam_role.lambda_role.arn
}
