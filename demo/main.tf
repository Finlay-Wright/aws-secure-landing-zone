# Single Account Demo
# This is a simplified version for demonstration purposes only
# In production, you would use separate logging and security accounts

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"

  default_tags {
    tags = {
      ManagedBy   = "terraform"
      Project     = "aws-secure-landing-zone-demo"
      Environment = "demo"
    }
  }
}

# Get current account ID
data "aws_caller_identity" "current" {}

# For demo purposes, we'll use the same account for everything
# In production, these would be separate accounts
locals {
  account_id = data.aws_caller_identity.current.account_id

  # In real deployment, these would be different account IDs
  logging_account_id  = local.account_id
  security_account_id = local.account_id
}

# Create a demo S3 bucket to simulate the central logging bucket
resource "aws_s3_bucket" "demo_logging" {
  bucket = "demo-central-logging-${local.account_id}"

  tags = {
    Name        = "Demo Central Logging Bucket"
    Environment = "Demo"
  }
}

resource "aws_s3_bucket_public_access_block" "demo_logging" {
  bucket = aws_s3_bucket.demo_logging.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "demo_logging" {
  bucket = aws_s3_bucket.demo_logging.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Deploy KMS encryption module first (logging needs the KMS keys)
module "kms_encryption" {
  source = "../../modules/kms-encryption"

  # Account identification
  account_name    = "demo-account"
  environment     = "demo"
  logging_account_id = local.logging_account_id

  # EBS encryption configuration
  enable_ebs_encryption_by_default = true

  tags = {
    Module = "kms-encryption"
    Demo   = "true"
  }
}

# Deploy centralized logging module
module "centralized_logging" {
  source = "../../modules/centralized-logging"

  # Account identification
  account_name       = "demo-account"
  environment        = "demo"
  logging_account_id = local.logging_account_id

  # Logging destinations
  central_logging_bucket_arn = aws_s3_bucket.demo_logging.arn

  # KMS keys from encryption module
  cloudwatch_logs_kms_key_arn = module.kms_encryption.cloudwatch_logs_key_arn
  flow_logs_kms_key_arn       = module.kms_encryption.flow_logs_key_arn

  # CloudTrail configuration
  cloudtrail_name                  = "demo-baseline-trail"
  cloudtrail_log_retention_days    = 90
  enable_cloudtrail_log_validation = true

  # GuardDuty configuration
  enable_guardduty                       = true
  guardduty_finding_publishing_frequency = "FIFTEEN_MINUTES"

  tags = {
    Module = "centralized-logging"
    Demo   = "true"
  }
}

# Deploy tagging enforcement module
module "tagging_enforcement" {
  source = "../../modules/tagging-enforcement"

  # Account identification
  account_name = "demo-account"
  environment  = "demo"

  # Required tag keys for all resources
  required_tag_keys = ["Project", "Team", "Environment"]

  tags = {
    Module = "tagging-enforcement"
    Demo   = "true"
  }
}
