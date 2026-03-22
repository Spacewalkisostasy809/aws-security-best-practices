variable "environment" {
  description = "vulnerable or remediated"
  type        = string
}

variable "enforce_imdsv2" {
  description = "Require IMDSv2 (set to false for vulnerable)"
  type        = bool
  default     = true
}

variable "allow_ssh_from_world" {
  description = "Allow SSH from 0.0.0.0/0 (set to true for vulnerable)"
  type        = bool
  default     = false
}

variable "encrypt_ebs" {
  description = "Encrypt EBS volumes (set to false for vulnerable)"
  type        = bool
  default     = true
}

variable "attach_admin_role" {
  description = "Attach AdministratorAccess to instance role (set to true for vulnerable)"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID to deploy into"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID to deploy into"
  type        = string
}
