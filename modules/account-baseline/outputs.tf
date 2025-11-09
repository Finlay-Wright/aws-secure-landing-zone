# KMS Encryption Module Outputs
output "kms_key_ids" {
  description = "Map of KMS key IDs by purpose"
  value       = module.kms_encryption.kms_key_ids
}

output "kms_key_arns" {
  description = "Map of KMS key ARNs by purpose"
  value       = module.kms_encryption.kms_key_arns
}

output "ebs_encryption_enabled" {
  description = "Whether EBS encryption by default is enabled"
  value       = module.kms_encryption.ebs_encryption_enabled
}

output "ebs_default_kms_key_arn" {
  description = "ARN of the default KMS key for EBS encryption"
  value       = module.kms_encryption.ebs_default_kms_key_arn
}

# Centralized Logging Module Outputs
output "cloudtrail_id" {
  description = "ID of the CloudTrail trail"
  value       = module.centralized_logging.cloudtrail_id
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = module.centralized_logging.cloudtrail_arn
}

output "cloudtrail_log_group_arn" {
  description = "ARN of the CloudTrail CloudWatch log group"
  value       = module.centralized_logging.cloudtrail_log_group_arn
}

output "guardduty_detector_id" {
  description = "ID of the GuardDuty detector"
  value       = module.centralized_logging.guardduty_detector_id
}

output "default_vpc_flow_log_id" {
  description = "ID of the default VPC flow log"
  value       = module.centralized_logging.default_vpc_flow_log_id
}

output "flow_logs_log_group_arn" {
  description = "ARN of the VPC Flow Logs CloudWatch log group"
  value       = module.centralized_logging.flow_logs_log_group_arn
}

# Tagging Enforcement Module Outputs
output "config_rule_arns" {
  description = "ARNs of Config rules for tag enforcement"
  value       = module.tagging_enforcement.config_rule_arns
}

output "required_tag_keys" {
  description = "List of required tag keys"
  value       = module.tagging_enforcement.required_tag_keys
}
