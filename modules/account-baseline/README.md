# Account Baseline Module

Wrapper that combines all the security modules into one easy package.

## What This Does

This calls three other modules:
- **kms-encryption** - Creates KMS keys, enables EBS encryption
- **centralized-logging** - Sets up CloudTrail, GuardDuty, VPC Flow Logs
- **tagging-enforcement** - Config rules for required tags

Think of it as a convenience module - instead of calling each module separately, you call this one and get everything.

## When to Use This

**Use this wrapper if:**
- You're setting up a new account and want all the security controls
- You want simplicity over fine-grained control
- You're okay with the default configuration

**Use individual modules if:**
- You only need some controls (e.g., just logging, not tagging)
- You want more control over how modules are wired together
- You're adding security to an existing account incrementally

## Usage

```hcl
module "account_baseline" {
  source = "./modules/account-baseline"

  account_name = "my-prod-account"
  environment  = "prod"

  # Where logs go
  central_logging_bucket_arn = "arn:aws:s3:::my-org-logging-bucket"
  security_account_id        = "123456789012"
  logging_account_id         = "234567890123"

  # Regions
  primary_region  = "eu-west-2"
  enabled_regions = ["eu-west-2", "eu-west-1"]

  # Required tags
  required_tags = {
    Environment        = "prod"
    Owner              = "platform@aisi.gov.uk"
    DataClassification = "super-secret"
  }
}
```

## What Gets Created

### From kms-encryption module:
- 4 KMS keys (EBS, CloudWatch Logs, Flow Logs, Data)
- EBS encryption turned on by default
- **Cost:** $4/month

### From centralized-logging module:
- Multi-region CloudTrail
- GuardDuty threat detection
- VPC Flow Logs for default VPC
- CloudWatch Logs (encrypted)
- **Cost:** ~$20-100/month depending on volume

### From tagging-enforcement module:
- AWS Config rules for 4 required tags
- Compliance dashboard
- **Cost:** ~$8-10/month

**Total:** ~$32-114/month for a typical production account

## Module Flow

```
kms-encryption (no dependencies)
       ↓ (provides KMS key ARNs)
centralized-logging (needs KMS keys)
       ↓
tagging-enforcement (no dependencies)
```

The wrapper handles passing KMS key outputs to the logging module, so you don't have to wire them up manually.

## Customisation

All the variables from the sub-modules are exposed, so you can customise:

```hcl
module "account_baseline" {
  source = "./modules/account-baseline"
  # ... required variables ...

  # Customize retention
  cloudtrail_log_retention_days = 365  # Keep logs longer
  flow_logs_retention_days      = 7    # Keep logs shorter

  # Disable features
  enable_guardduty              = false  # Turn off threat detection
  enable_default_vpc_flow_logs  = false  # Don't log default VPC

  # Customize KMS
  kms_key_deletion_window = 7  # Faster deletion (not recommended for prod)
}
```

## Using Individual Modules Instead

If you want more control, skip this wrapper and use the modules directly:

```hcl
# Step 1: KMS keys
module "kms" {
  source = "./modules/kms-encryption"
  # ... config ...
}

# Step 2: Logging (uses KMS keys)
module "logging" {
  source = "./modules/centralized-logging"

  cloudwatch_logs_kms_key_arn = module.kms.cloudwatch_logs_key_arn
  flow_logs_kms_key_arn       = module.kms.flow_logs_key_arn
  # ... config ...

  depends_on = [module.kms]
}

# Step 3: Tagging
module "tagging" {
  source = "./modules/tagging-enforcement"
  # ... config ...
}
```

See individual module READMEs for detailed docs:
- [kms-encryption](../kms-encryption/README.md)
- [centralized-logging](../centralized-logging/README.md)
- [tagging-enforcement](../tagging-enforcement/README.md)

## Outputs

This wrapper passes through outputs from the sub-modules:

- `kms_key_arns` - Map of KMS key ARNs
- `cloudtrail_arn` - CloudTrail trail ARN
- `guardduty_detector_id` - GuardDuty detector ID
- `config_rule_arns` - Config rule ARNs for tagging

See [outputs.tf](outputs.tf) for the full list.

## What's Not Included

This baseline doesn't include:
- **SCPs** - Those are deployed at the organization level, not account level (see `/scps` directory) for some suggested ones.
- **Network configuration** - You would still need to create VPCs, subnets, etc.
- **Application resources** - This is just the security foundation

This is just the first piece you deploy into a new account, then you build your actual infrastructure on top of it.
