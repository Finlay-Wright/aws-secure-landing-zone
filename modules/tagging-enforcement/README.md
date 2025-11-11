# Tagging Enforcement Module

**Deliverable C** - Tag compliance monitoring via AWS Config.

## Overview

AWS Config rules to check for required tags. Non-compliant resources show up in the Config dashboard. This is detective control - resources can still be created without tags, but you'll hear about it.

**Default tags:**
- `Environment` - dev/staging/prod
- `Owner` - Responsible team/person
- `CostCenter` - For billing/chargeback
- `DataClassification` - Sensitivity level

**Why:** Cost allocation, accountability, automation, compliance. Without enforcement tags drift over time and become useless.

**Optional auto-remediation:** A fairly heavily vibe coded Lambda function included to automatically tag non-compliant resources. Can be enabled via `enable_auto_remediation = true`.

## Usage

```hcl
module "tagging_enforcement" {
  source = "./modules/tagging-enforcement"

  account_name = "my-prod-account"
  environment  = "prod"

  required_tag_keys = ["Environment", "Owner", "CostCenter", "DataClassification"]

  required_tags = {
    Environment        = "prod"
    Owner              = "platform-team@company.com"
    CostCenter         = "engineering"
    DataClassification = "confidential"
  }

  resource_types = [
    "AWS::EC2::Instance",
    "AWS::S3::Bucket",
    "AWS::RDS::DBInstance",
  ]
}
```

## Resources Created

- AWS Config rules (one per required tag)
- Rule to validate tag values match environment expectations
- Compliance reporting via Config dashboard
- (Optional) Lambda function for auto-remediation
- (Optional) EventBridge rule to trigger Lambda on compliance changes
- (Optional) SSM parameter for default tag values

**Cost:**
- Config rules: ~$2 per rule = $8-10/month for 4-5 rules
- Auto-remediation Lambda: ~$0.20/month (free tier covers most usage)
- EventBridge: Free for this usage pattern

## Limitations

**Detective, not preventive:** Resources can be created without tags - this just flags them as non-compliant. For preventive enforcement, use Tag Policies or SCPs (not included in this module).

**Config rule evaluation:** Runs periodically and on resource changes. There's a delay between creation and detection.

## Automated Remediation

This module now includes optional automated tag remediation via Lambda.

When enabled, a Lambda function automatically applies default tags to non-compliant resources when Config detects violations.

**How it works:**
1. Config detects a resource without required tags and marks it NON_COMPLIANT
2. EventBridge triggers Lambda on compliance change
3. Lambda retrieves default tags from SSM Parameter Store
4. Lambda applies tags using Resource Groups Tagging API
5. If resource type doesn't support auto-tagging then it sends SNS notification

**What gets auto-tagged:**
EC2 instances/volumes, S3 buckets, RDS databases, Lambda functions, DynamoDB tables, ECS/EKS clusters, EFS file systems. See `lambda/auto_tag_remediation.py` for full list.

**Tags applied:**
- Missing required tags from SSM parameter `/baseline/default-tags`
- `AutoTaggedBy: baseline-remediation`
- `AutoTaggedDate: YYYY-MM-DD`

**Doesn't overwrite:** Existing tags are preserved - only missing tags are added.

**Manual remediation (if auto-remediation is disabled):**

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `account_name` | Account identifier | Required |
| `environment` | Environment tier | Required |
| `required_tag_keys` | List of required tag names | See variables.tf |
| `required_tags` | Expected tag values | {} |
| `resource_types` | Resource types to check | Common types |
| `enable_config_rules` | Enable Config | true |
| `enable_auto_remediation` | Enable Lambda auto-tagging | false |
| `remediation_sns_topic_arn` | SNS topic for remediation alerts | "" |
| `create_default_tags_parameter` | Create SSM parameter with defaults | true |

## Outputs

- `config_rule_arns` - ARNs of created Config rules
- `config_rule_names` - Names of created Config rules
- `remediation_lambda_arn` - ARN of remediation Lambda (if enabled)
- `remediation_lambda_name` - Name of remediation Lambda (if enabled)
- `remediation_eventbridge_rule_arn` - ARN of EventBridge trigger (if enabled)
