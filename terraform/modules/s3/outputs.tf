output "bucket_name" {
  value = aws_s3_bucket.test_bucket.id
}

output "bucket_arn" {
  value = aws_s3_bucket.test_bucket.arn
}

output "is_public" {
  value = var.make_bucket_public ? "YES — CRITICAL finding expected" : "NO — bucket is private"
}
