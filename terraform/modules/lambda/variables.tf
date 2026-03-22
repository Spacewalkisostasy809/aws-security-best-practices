variable "environment" {
  description = "vulnerable or remediated"
  type        = string
}

variable "store_secrets_in_env_vars" {
  description = "Put secrets directly in env vars (true for vulnerable)"
  type        = bool
  default     = false
}

variable "enable_public_url" {
  description = "Create a Lambda URL with AuthType NONE (true for vulnerable)"
  type        = bool
  default     = false
}

variable "use_admin_execution_role" {
  description = "Attach AdministratorAccess to Lambda execution role (true for vulnerable)"
  type        = bool
  default     = false
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}
