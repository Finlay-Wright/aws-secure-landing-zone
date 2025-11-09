# CloudTrail outputs
output "cloudtrail_id" {
  description = "ID of the CloudTrail trail"
  value       = aws_cloudtrail.main.id
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = aws_cloudtrail.main.arn
}

output "cloudtrail_log_group_arn" {
  description = "ARN of the CloudTrail CloudWatch log group"
  value       = aws_cloudwatch_log_group.cloudtrail.arn
}

output "cloudtrail_log_group_name" {
  description = "Name of the CloudTrail CloudWatch log group"
  value       = aws_cloudwatch_log_group.cloudtrail.name
}

# GuardDuty outputs
output "guardduty_detector_id" {
  description = "ID of the GuardDuty detector (null if disabled)"
  value       = var.enable_guardduty ? aws_guardduty_detector.main[0].id : null
}

output "guardduty_detector_arn" {
  description = "ARN of the GuardDuty detector (null if disabled)"
  value       = var.enable_guardduty ? aws_guardduty_detector.main[0].arn : null
}

# VPC Flow Logs outputs
output "default_vpc_flow_log_id" {
  description = "ID of the default VPC flow log (null if disabled)"
  value       = var.enable_default_vpc_flow_logs ? aws_flow_log.default_vpc[0].id : null
}

output "flow_logs_log_group_arn" {
  description = "ARN of the VPC Flow Logs CloudWatch log group (null if disabled)"
  value       = var.enable_default_vpc_flow_logs ? aws_cloudwatch_log_group.flow_logs[0].arn : null
}

output "flow_logs_log_group_name" {
  description = "Name of the VPC Flow Logs CloudWatch log group (null if disabled)"
  value       = var.enable_default_vpc_flow_logs ? aws_cloudwatch_log_group.flow_logs[0].name : null
}
