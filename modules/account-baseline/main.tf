# Account Baseline Module
# This is a wrapper module that combines all security controls

# Local variables
locals {
  # Merged tags
  common_tags = merge(
    var.required_tags,
    var.additional_tags,
    {
      ManagedBy = "terraform"
      Module    = "account-baseline"
    }
  )
}

# KMS Encryption Module
module "kms_encryption" {
  source = "../kms-encryption"

  account_name       = var.account_name
  environment        = var.environment
  logging_account_id = var.logging_account_id

  kms_key_deletion_window          = var.kms_key_deletion_window
  enable_kms_key_rotation          = var.enable_kms_key_rotation
  enable_ebs_encryption_by_default = var.enable_ebs_encryption_by_default

  tags = local.common_tags
}

# Centralized Logging Module
module "centralized_logging" {
  source = "../centralized-logging"

  account_name               = var.account_name
  environment                = var.environment
  central_logging_bucket_arn = var.central_logging_bucket_arn
  logging_account_id         = var.logging_account_id

  # KMS keys from encryption module
  cloudwatch_logs_kms_key_arn = module.kms_encryption.cloudwatch_logs_key_arn
  flow_logs_kms_key_arn       = module.kms_encryption.flow_logs_key_arn

  # CloudTrail configuration
  cloudtrail_name                  = var.cloudtrail_name
  enable_cloudtrail_log_validation = var.enable_cloudtrail_log_validation
  cloudtrail_log_retention_days    = var.cloudtrail_log_retention_days

  # GuardDuty configuration
  enable_guardduty                       = var.enable_guardduty
  guardduty_finding_publishing_frequency = var.guardduty_finding_publishing_frequency

  # VPC Flow Logs configuration
  enable_default_vpc_flow_logs = var.enable_default_vpc_flow_logs
  flow_logs_retention_days     = var.flow_logs_retention_days

  tags = local.common_tags

  depends_on = [module.kms_encryption]
}

# Tagging Enforcement Module
module "tagging_enforcement" {
  source = "../tagging-enforcement"

  account_name      = var.account_name
  environment       = var.environment
  required_tag_keys = var.required_tag_keys
  required_tags     = var.required_tags

  enable_config_rules = var.tag_enforcement_method == "config" || var.tag_enforcement_method == "both"

  tags = local.common_tags
}
