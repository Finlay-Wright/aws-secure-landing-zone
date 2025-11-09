# Centralized Logging Module

**Deliverable A** - CloudTrail, VPC Flow Logs, GuardDuty, and CloudWatch Logs.

## Overview

Enables comprehensive audit logging for the account. All logs sent to central S3 bucket and encrypted with KMS.

**Components:**
- CloudTrail - API call logging (multi-region, log validation enabled)
- VPC Flow Logs - Network traffic metadata
- GuardDuty - Threat detection (ML-based anomaly detection)
- CloudWatch Logs - Centralized log storage with retention policies

**Why:** Required for incident response, compliance (SOC 2, ISO 27001, CIS Benchmark), and threat detection. Without this you're blind to account activity.

## Usage

```hcl
module "centralized_logging" {
  source = "./modules/centralized-logging"

  account_name               = "my-prod-account"
  environment                = "prod"
  central_logging_bucket_arn = "arn:aws:s3:::my-org-logging-bucket"
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
- VPC Flow Logs for all VPCs (including default VPC)
- GuardDuty detector with findings export
- CloudWatch Log Groups (encrypted with KMS)

**Cost:** ~$20-80/month depending on API volume and traffic. CloudTrail management events are cheap ($5-10), GuardDuty and Flow Logs scale with usage.

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

## Compliance

CIS AWS Foundations: 3.1, 3.2, 3.4, 3.9

## Cost Estimate

For a typical production account, expect around $30-100/month:
- CloudTrail: $5-10
- GuardDuty: $10-40
- VPC Flow Logs: $15-50
- CloudWatch storage: $5-10

Dev/test accounts will be cheaper since there's less activity.

## Common Issues

**CloudTrail not logging:**
Check that the central S3 bucket policy allows CloudTrail to write. The bucket needs to allow the CloudTrail service to put objects.

**GuardDuty not finding anything:**
That's actually good! It takes 24-48 hours to baseline normal behavior. If you want to test it, you can generate sample findings in the GuardDuty console.

**Flow Logs not appearing:**
Make sure the default VPC exists (some regions don't have one). If you deleted it, either recreate it or set `enable_default_vpc_flow_logs = false`.

## What This Doesn't Do

This module just sets up the logging infrastructure. You'll still need to:
- Set up alerts on GuardDuty findings (use EventBridge + SNS)
- Actually review the logs regularly
- Configure a SIEM if you want fancy correlation
- Set up log analysis queries in CloudWatch Insights

Also, this only logs the default VPC. For other VPCs you create, you'll need to add Flow Logs separately (or use this module as a template).
