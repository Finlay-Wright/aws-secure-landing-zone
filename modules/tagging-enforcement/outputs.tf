# Config rule outputs
output "config_rule_arns" {
  description = "ARNs of the Config rules created for tag enforcement"
  value = var.enable_config_rules ? {
    for tag_key, rule in aws_config_config_rule.required_tags :
    tag_key => rule.arn
  } : {}
}

output "config_rule_names" {
  description = "Names of the Config rules created for tag enforcement"
  value = var.enable_config_rules ? {
    for tag_key, rule in aws_config_config_rule.required_tags :
    tag_key => rule.name
  } : {}
}

output "required_tag_keys" {
  description = "List of required tag keys enforced by this module"
  value       = var.required_tag_keys
}

output "required_tags" {
  description = "Map of required tags with values for this account"
  value       = var.required_tags
}

# Remediation Lambda outputs
output "remediation_lambda_arn" {
  description = "ARN of the tag remediation Lambda function"
  value       = var.enable_auto_remediation ? aws_lambda_function.tag_remediation[0].arn : null
}

output "remediation_lambda_name" {
  description = "Name of the tag remediation Lambda function"
  value       = var.enable_auto_remediation ? aws_lambda_function.tag_remediation[0].function_name : null
}

output "remediation_eventbridge_rule_arn" {
  description = "ARN of the EventBridge rule triggering remediation"
  value       = var.enable_auto_remediation ? aws_cloudwatch_event_rule.config_compliance_change[0].arn : null
}
