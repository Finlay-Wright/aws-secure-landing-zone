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
variable "central_logging_bucket_arn" {
  description = "ARN of the central S3 bucket for CloudTrail logs"
  type        = string
}

variable "logging_account_id" {
  description = "AWS account ID of the logging account"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.logging_account_id))
    error_message = "Logging account ID must be a 12-digit number."
  }
}

# KMS key ARNs (from kms-encryption module)
variable "cloudwatch_logs_kms_key_arn" {
  description = "ARN of KMS key for CloudWatch Logs encryption"
  type        = string
}

variable "flow_logs_kms_key_arn" {
  description = "ARN of KMS key for VPC Flow Logs encryption"
  type        = string
}

# CloudTrail configuration
variable "cloudtrail_name" {
  description = "Name of the CloudTrail trail (defaults to account-name-cloudtrail)"
  type        = string
  default     = null
}

variable "enable_cloudtrail_log_validation" {
  description = "Enable CloudTrail log file validation to detect tampering"
  type        = bool
  default     = true
}

variable "cloudtrail_log_retention_days" {
  description = "Number of days to retain CloudTrail logs in CloudWatch Logs"
  type        = number
  default     = 90

  validation {
    condition     = var.cloudtrail_log_retention_days > 0
    error_message = "CloudTrail log retention must be at least 1 day."
  }
}

# GuardDuty configuration
variable "enable_guardduty" {
  description = "Enable GuardDuty threat detection"
  type        = bool
  default     = true
}

variable "guardduty_finding_publishing_frequency" {
  description = "Frequency of GuardDuty findings publication"
  type        = string
  default     = "FIFTEEN_MINUTES"

  validation {
    condition     = contains(["FIFTEEN_MINUTES", "ONE_HOUR", "SIX_HOURS"], var.guardduty_finding_publishing_frequency)
    error_message = "Finding publishing frequency must be FIFTEEN_MINUTES, ONE_HOUR, or SIX_HOURS."
  }
}

# VPC Flow Logs configuration
variable "enable_default_vpc_flow_logs" {
  description = "Enable VPC Flow Logs for the default VPC"
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "Number of days to retain VPC Flow Logs in CloudWatch Logs"
  type        = number
  default     = 30

  validation {
    condition     = var.flow_logs_retention_days > 0
    error_message = "Flow logs retention must be at least 1 day."
  }
}

# Tags
variable "tags" {
  description = "Tags to apply to all logging resources"
  type        = map(string)
  default     = {}
}
