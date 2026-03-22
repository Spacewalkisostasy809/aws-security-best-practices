output "db_endpoint" {
  value = aws_db_instance.test_db.endpoint
}

output "db_identifier" {
  value = aws_db_instance.test_db.identifier
}

output "publicly_accessible" {
  value = var.publicly_accessible ? "YES — CRITICAL finding expected" : "NO — private"
}

output "storage_encrypted" {
  value = var.storage_encrypted ? "YES — encrypted" : "NO — CRITICAL finding expected"
}
