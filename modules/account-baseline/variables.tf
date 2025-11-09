# Account identification
variable "account_name" {
  description = "Name of the AWS account being secured"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# Cross-account configuration
variable "central_logging_bucket_arn" {
  description = "ARN of the central S3 bucket for CloudTrail and other logs"
  type        = string
}

variable "security_account_id" {
  description = "AWS account ID of the security account"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.security_account_id))
    error_message = "Security account ID must be a 12-digit number."
  }
}

variable "logging_account_id" {
  description = "AWS account ID of the logging account"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.logging_account_id))
    error_message = "Logging account ID must be a 12-digit number."
  }
}

# Regional configuration
# Defaults to London (eu-west-2) for data residency, but can be overridden by setting these variables
# when calling the module. The SCP region restriction should match these settings.
variable "primary_region" {
  description = "Primary AWS region for resources (override for different regions)"
  type        = string
  default     = "eu-west-2"
}

variable "enabled_regions" {
  description = "List of AWS regions where resources can be created (override for multi-region)"
  type        = list(string)
  default     = ["eu-west-2"]
}

# Tagging
variable "required_tags" {
  description = "Required tags for all resources"
  type        = map(string)
  default = {
    Environment        = "dev"
    Owner              = "platform-team"
    CostCenter         = "engineering"
    DataClassification = "internal"
  }
}

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# CloudTrail configuration
variable "cloudtrail_name" {
  description = "Name of the CloudTrail trail"
  type        = string
  default     = null
}

variable "enable_cloudtrail_log_validation" {
  description = "Enable CloudTrail log file validation"
  type        = bool
  default     = true
}

variable "cloudtrail_log_retention_days" {
  description = "Number of days to retain CloudTrail logs in CloudWatch Logs"
  type        = number
  default     = 90
}

# GuardDuty configuration
variable "enable_guardduty" {
  description = "Enable GuardDuty threat detection"
  type        = bool
  default     = true
}

variable "guardduty_finding_publishing_frequency" {
  description = "Frequency of GuardDuty findings publication (FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS)"
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
  description = "Number of days to retain VPC Flow Logs"
  type        = number
  default     = 30
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
  description = "Enable automatic KMS key rotation"
  type        = bool
  default     = true
}

# EBS encryption
variable "enable_ebs_encryption_by_default" {
  description = "Enable EBS encryption by default"
  type        = bool
  default     = true
}

# Tagging enforcement
variable "tag_enforcement_method" {
  description = "Method for tag enforcement (config, tag_policy, or both)"
  type        = string
  default     = "config"

  validation {
    condition     = contains(["config", "tag_policy", "both"], var.tag_enforcement_method)
    error_message = "Tag enforcement method must be config, tag_policy, or both."
  }
}

variable "required_tag_keys" {
  description = "List of required tag keys for compliance"
  type        = list(string)
  default     = ["Environment", "Owner", "CostCenter", "DataClassification"]
}
