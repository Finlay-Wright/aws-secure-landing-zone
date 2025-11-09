# Account identification
variable "account_name" {
  description = "Name of the AWS account"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

# Tagging configuration
variable "required_tag_keys" {
  description = "List of tag keys that must be present on resources"
  type        = list(string)
  default     = ["Environment", "Owner", "CostCenter", "DataClassification"]

  validation {
    condition     = length(var.required_tag_keys) > 0
    error_message = "At least one required tag key must be specified."
  }
}

variable "required_tags" {
  description = "Map of required tags with expected values for this account"
  type        = map(string)
  default = {
    Environment        = "dev"
    Owner              = "platform-team"
    CostCenter         = "engineering"
    DataClassification = "internal"
  }
}

variable "resource_types" {
  description = "List of AWS resource types to enforce tagging on"
  type        = list(string)
  default = [
    "AWS::EC2::Instance",
    "AWS::EC2::Volume",
    "AWS::S3::Bucket",
    "AWS::RDS::DBInstance",
    "AWS::Lambda::Function",
    "AWS::DynamoDB::Table",
    "AWS::ECS::Cluster",
    "AWS::EKS::Cluster",
  ]
}

variable "enable_config_rules" {
  description = "Enable AWS Config rules for tag enforcement"
  type        = bool
  default     = true
}

# Auto-remediation configuration
variable "enable_auto_remediation" {
  description = "Enable Lambda function to automatically tag non-compliant resources"
  type        = bool
  default     = false
}

variable "remediation_sns_topic_arn" {
  description = "SNS topic ARN for notifications when resources can't be auto-tagged (optional)"
  type        = string
  default     = ""
}

variable "create_default_tags_parameter" {
  description = "Create SSM parameter with default tags for remediation Lambda"
  type        = bool
  default     = true
}

# Tags
variable "tags" {
  description = "Tags to apply to Config resources"
  type        = map(string)
  default     = {}
}
