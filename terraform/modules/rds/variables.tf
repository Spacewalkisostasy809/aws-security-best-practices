variable "environment" {
  description = "vulnerable or remediated"
  type        = string
}

variable "publicly_accessible" {
  description = "Make RDS publicly accessible (set to true for vulnerable)"
  type        = bool
  default     = false
}

variable "storage_encrypted" {
  description = "Encrypt RDS storage (set to false for vulnerable)"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Enable deletion protection (set to false for vulnerable)"
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "Days to retain automated backups (set to 0 for vulnerable)"
  type        = number
  default     = 7
}

variable "iam_database_authentication_enabled" {
  description = "Enable IAM database authentication (set to false for vulnerable)"
  type        = bool
  default     = true
}

variable "db_password" {
  description = "Master database password"
  type        = string
  sensitive   = true
}

variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID for the RDS security group"
  type        = string
}

variable "allowed_cidr" {
  description = "CIDR allowed to connect to RDS (0.0.0.0/0 for vulnerable)"
  type        = string
  default     = "10.0.0.0/8"
}
