output "account_id" {
  description = "AWS Account ID used for this demo"
  value       = local.account_id
}

output "demo_logging_bucket" {
  description = "Demo S3 bucket for centralized logging"
  value       = aws_s3_bucket.demo_logging.id
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = module.centralized_logging.cloudtrail_arn
}

output "cloudtrail_log_group_name" {
  description = "Name of the CloudTrail CloudWatch log group"
  value       = module.centralized_logging.cloudtrail_log_group_name
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID"
  value       = module.centralized_logging.guardduty_detector_id
}

output "kms_key_ids" {
  description = "KMS key IDs created by the baseline"
  value = {
    ebs              = module.kms_encryption.ebs_key_id
    cloudwatch_logs  = module.kms_encryption.cloudwatch_logs_key_id
    vpc_flow_logs    = module.kms_encryption.flow_logs_key_id
    data             = module.kms_encryption.data_key_id
  }
}

output "kms_key_arns" {
  description = "KMS key ARNs created by the baseline"
  value = {
    ebs              = module.kms_encryption.ebs_key_arn
    cloudwatch_logs  = module.kms_encryption.cloudwatch_logs_key_arn
    vpc_flow_logs    = module.kms_encryption.flow_logs_key_arn
    data             = module.kms_encryption.data_key_arn
  }
}

output "config_rules" {
  description = "AWS Config rules for tagging enforcement"
  value       = module.tagging_enforcement.config_rule_names
}

output "ebs_encryption_enabled" {
  description = "Whether EBS encryption by default is enabled"
  value       = module.kms_encryption.ebs_encryption_enabled
}
