variable "environment" {
  description = "vulnerable or remediated"
  type        = string
}

variable "enforce_mfa" {
  description = "Attach a deny-without-MFA policy to IAM users"
  type        = bool
  default     = false
}

variable "create_dangerous_trust_role" {
  description = "Create a role with Principal: * in trust policy"
  type        = bool
  default     = false
}

variable "attach_admin_to_user" {
  description = "Attach AdministratorAccess directly to a user (bad practice)"
  type        = bool
  default     = false
}
