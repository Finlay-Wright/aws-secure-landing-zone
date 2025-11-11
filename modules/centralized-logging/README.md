# Centralized Logging Module

**Deliverable A** - CloudTrail, VPC Flow Logs, GuardDuty, and CloudWatch Logs.

## Overview

Enables comprehensive audit logging for the account. All logs sent to central S3 bucket and encrypted with KMS.

**Components:**
- CloudTrail - API call logging (multi-region, log validation enabled)
- VPC Flow Logs - Network traffic metadata
- GuardDuty - Threat detection
- CloudWatch Logs - Centralised log storage with retention policies

**Why:** In a multi-account organisation, centralising logs in one place makes security monitoring, incident response, and compliance auditing actually manageable. Without this, you would need to mointor/alert on logs from n number of accounts indivudually.

## Usage

```hcl
module "centralized_logging" {
  source = "./modules/centralized-logging"

  account_name               = "my-prod-account"
  environment                = "prod"
  central_logging_bucket_arn = "arn:aws:s3:::my-huge-logging-bucket"
  logging_account_id         = "123456789012"

  # KMS keys from kms-encryption module
  cloudwatch_logs_kms_key_arn = module.kms_encryption.cloudwatch_logs_key_arn
  flow_logs_kms_key_arn       = module.kms_encryption.flow_logs_key_arn

  cloudtrail_log_retention_days = 90
  flow_logs_retention_days      = 30
}
```

## Resources Created

- Multi-region CloudTrail with log validation
- VPC Flow Logs for default VPC (if it exists)
- GuardDuty detector with findings export
- CloudWatch Log Groups (encrypted with KMS)

**Cost:** ~$20-100/month depending on API volume and traffic. CloudTrail management events are cheap ($5-10), GuardDuty and Flow Logs scale with usage.

## Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `account_name` | Account identifier | Yes |
| `environment` | Environment tier | Yes |
| `central_logging_bucket_arn` | S3 bucket for CloudTrail | Yes |
| `logging_account_id` | Account that reads logs | Yes |
| `cloudwatch_logs_kms_key_arn` | KMS key for CloudWatch | Yes |
| `flow_logs_kms_key_arn` | KMS key for Flow Logs | Yes |

See `variables.tf` for full list.

## Outputs

- `cloudtrail_arn`
- `guardduty_detector_id`
- `cloudtrail_log_group_arn`
- `flow_logs_log_group_arn`

## Dependencies

Requires KMS keys to exist first. Create `kms-encryption` module before this one.

## Cost Estimate

For a typical production account, expect around $20-100/month:
- CloudTrail: $5-10
- GuardDuty: $10-40
- VPC Flow Logs: $15-50
- CloudWatch storage: $5-10

## What This Doesn't Do

This module just sets up the logging infrastructure. You still need to:
- Set up alerts on GuardDuty findings (use EventBridge + SNS)
- Configure a SIEM if you want fancy correlation
- Set up log analysis queries in CloudWatch Insights

Also, this only logs the default VPC (which in a real setup you really shouldn't be using!). For other VPCs you create, you'll need to add Flow Logs separately (or use this module as a template).
