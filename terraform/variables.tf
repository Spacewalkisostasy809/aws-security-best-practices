variable "region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Environment name — used in resource names and tags (vulnerable or remediated)"
  type        = string
  default     = "vulnerable"

  validation {
    condition     = contains(["vulnerable", "remediated"], var.environment)
    error_message = "environment must be 'vulnerable' or 'remediated'."
  }
}

variable "db_password" {
  description = "RDS master password — use a strong password for remediated, anything for vulnerable"
  type        = string
  sensitive   = true
  default     = "TestPassword123!"
}
