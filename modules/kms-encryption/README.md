# KMS Encryption Module

**Deliverable B** - Customer-managed KMS keys and EBS encryption by default.

## Overview

Creates 4 customer-managed KMS keys and enables account-wide EBS encryption. All keys have automatic rotation and CloudTrail logging.

**Keys:**
- `ebs` - Default key for EBS volumes
- `cloudwatch` - CloudWatch Logs encryption
- `flowlogs` - VPC Flow Logs encryption  
- `data` - General purpose (S3, RDS, DynamoDB, etc.)

**Why separate keys:** Limits blast radius if compromised, simpler key policies, easier permission management. Trade-off is cost ($1/key = $4/month vs $1 for one key).

**Why customer-managed:** Control over key policies, CloudTrail audit trail, ability to disable/delete, required for most compliance frameworks.

## Usage

```hcl
module "kms_encryption" {
  source = "./modules/kms-encryption"

  account_name       = "my-prod-account"
  environment        = "prod"
  logging_account_id = "123456789012"  # Grant decrypt for logs

  kms_key_deletion_window          = 30
  enable_kms_key_rotation          = true
  enable_ebs_encryption_by_default = true
}
```

## Resources Created

- 4 KMS keys with automatic rotation (annual)
- KMS key aliases for easy reference
- EBS encryption enabled account-wide
- Default EBS KMS key set

**Cost:** $4/month ($1 per key). API calls are free for first 20k/month.

## EBS Encryption By Default

Once enabled, all new EBS volumes are automatically encrypted. Users cannot create unencrypted volumes even if they try. The `ebs` key is used by default.

## Service Encryption Examples

**S3:**
```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.example.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = module.kms_encryption.data_key_arn
    }
  }
}
```

**RDS:**
```hcl
resource "aws_db_instance" "example" {
  storage_encrypted = true
  kms_key_id        = module.kms_encryption.data_key_arn
  # ... other config
}
```

**DynamoDB:**
```hcl
resource "aws_dynamodb_table" "example" {
  server_side_encryption {
    enabled     = true
    kms_key_arn = module.kms_encryption.data_key_arn
  }
  # ... other config
}
```

**EFS:**
```hcl
resource "aws_efs_file_system" "example" {
  encrypted  = true
  kms_key_id = module.kms_encryption.data_key_arn
  # ... other config
}
```

**OpenSearch:**
```hcl
resource "aws_opensearch_domain" "example" {
  encrypt_at_rest {
    enabled    = true
    kms_key_id = module.kms_encryption.data_key_arn
  }
  # ... other config
}
```

**SNS:**
```hcl
resource "aws_sns_topic" "example" {
  kms_master_key_id = module.kms_encryption.data_key_arn
  # ... other config
}
```

**SQS:**
```hcl
resource "aws_sqs_queue" "example" {
  kms_master_key_id                 = module.kms_encryption.data_key_arn
  kms_data_key_reuse_period_seconds = 300
  # ... other config
}
```

**Secrets Manager:**
```hcl
resource "aws_secretsmanager_secret" "example" {
  kms_key_id = module.kms_encryption.data_key_arn
  # ... other config
}
```

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `account_name` | Account identifier | Required |
| `environment` | Environment tier | Required |
| `logging_account_id` | Account for log decryption | Required |
| `kms_key_deletion_window` | Days before deletion | 30 |
| `enable_kms_key_rotation` | Auto-rotate keys | true |
| `enable_ebs_encryption_by_default` | Force EBS encryption | true |

## Outputs

- `ebs_key_arn`, `ebs_key_id`
- `cloudwatch_logs_key_arn`, `cloudwatch_logs_key_id`
- `flow_logs_key_arn`, `flow_logs_key_id`
- `data_key_arn`, `data_key_id`

## Key Policies

Each key has policies scoped to its purpose:
- **EBS:** EC2 service can encrypt/decrypt for volume operations
- **CloudWatch:** CloudWatch Logs service can encrypt/decrypt
- **Flow Logs:** VPC Flow Logs service can encrypt/decrypt
- **Data:** S3, RDS services can use; logging account can decrypt

All keys grant the account root full access (required for key management).


## What This Doesn't Do

This creates the keys, but doesn't automatically encrypt existing resources. You'll need to:
- Manually encrypt existing S3 buckets (or create new encrypted ones)
- Take encrypted snapshots of existing RDS databases and restore to new encrypted instances
- Existing EBS volumes stay unencrypted (new ones are encrypted)

Also doesn't set up key policies for every possible AWS service - just the common ones. If you use something exotic, you might need to update the key policies.
