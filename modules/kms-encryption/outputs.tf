# KMS key IDs
output "kms_key_ids" {
  description = "Map of KMS key IDs by purpose"
  value = {
    ebs        = aws_kms_key.ebs.id
    cloudwatch = aws_kms_key.cloudwatch_logs.id
    flow_logs  = aws_kms_key.flow_logs.id
    data       = aws_kms_key.data.id
  }
}

# KMS key ARNs
output "kms_key_arns" {
  description = "Map of KMS key ARNs by purpose"
  value = {
    ebs        = aws_kms_key.ebs.arn
    cloudwatch = aws_kms_key.cloudwatch_logs.arn
    flow_logs  = aws_kms_key.flow_logs.arn
    data       = aws_kms_key.data.arn
  }
}

# Individual key outputs for module dependencies
output "ebs_key_id" {
  description = "ID of the EBS encryption KMS key"
  value       = aws_kms_key.ebs.id
}

output "ebs_key_arn" {
  description = "ARN of the EBS encryption KMS key"
  value       = aws_kms_key.ebs.arn
}

output "cloudwatch_logs_key_id" {
  description = "ID of the CloudWatch Logs encryption KMS key"
  value       = aws_kms_key.cloudwatch_logs.id
}

output "cloudwatch_logs_key_arn" {
  description = "ARN of the CloudWatch Logs encryption KMS key"
  value       = aws_kms_key.cloudwatch_logs.arn
}

output "flow_logs_key_id" {
  description = "ID of the VPC Flow Logs encryption KMS key"
  value       = aws_kms_key.flow_logs.id
}

output "flow_logs_key_arn" {
  description = "ARN of the VPC Flow Logs encryption KMS key"
  value       = aws_kms_key.flow_logs.arn
}

output "data_key_id" {
  description = "ID of the data encryption KMS key (for S3, RDS, etc.)"
  value       = aws_kms_key.data.id
}

output "data_key_arn" {
  description = "ARN of the data encryption KMS key (for S3, RDS, etc.)"
  value       = aws_kms_key.data.arn
}

# EBS encryption status
output "ebs_encryption_enabled" {
  description = "Whether EBS encryption by default is enabled"
  value       = aws_ebs_encryption_by_default.main.enabled
}

output "ebs_default_kms_key_arn" {
  description = "ARN of the default KMS key for EBS encryption"
  value       = aws_ebs_default_kms_key.main.key_arn
}
