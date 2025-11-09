# Account identification
variable "account_name" {
  description = "Name of the AWS account"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

# Cross-account configuration
variable "logging_account_id" {
  description = "AWS account ID of the logging account (for cross-account key access)"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.logging_account_id))
    error_message = "Logging account ID must be a 12-digit number."
  }
}

# KMS configuration
variable "kms_key_deletion_window" {
  description = "Number of days before KMS key deletion (7-30)"
  type        = number
  default     = 30

  validation {
    condition     = var.kms_key_deletion_window >= 7 && var.kms_key_deletion_window <= 30
    error_message = "KMS key deletion window must be between 7 and 30 days."
  }
}

variable "enable_kms_key_rotation" {
  description = "Enable automatic annual KMS key rotation"
  type        = bool
  default     = true
}

# EBS encryption
variable "enable_ebs_encryption_by_default" {
  description = "Enable EBS encryption by default for all new volumes"
  type        = bool
  default     = true
}

# Tags
variable "tags" {
  description = "Tags to apply to all KMS keys"
  type        = map(string)
  default     = {}
}
