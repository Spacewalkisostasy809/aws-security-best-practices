variable "environment" {
  description = "vulnerable or remediated"
  type        = string
}

variable "block_public_access" {
  description = "Enable S3 Block Public Access (set to false for vulnerable)"
  type        = bool
  default     = true
}

variable "enable_encryption" {
  description = "Enable default bucket encryption (set to false for vulnerable)"
  type        = bool
  default     = true
}

variable "enable_versioning" {
  description = "Enable bucket versioning (set to false for vulnerable)"
  type        = bool
  default     = true
}

variable "make_bucket_public" {
  description = "Attach a public bucket policy with Principal: * (set to true for vulnerable)"
  type        = bool
  default     = false
}

variable "account_id" {
  description = "AWS account ID — used to scope bucket policy in remediated"
  type        = string
}
