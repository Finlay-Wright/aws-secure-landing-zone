# KMS key for EBS encryption
resource "aws_kms_key" "ebs" {
  description             = "KMS key for EBS volume encryption in ${var.account_name}"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = var.enable_kms_key_rotation

  tags = merge(
    local.common_tags,
    {
      Name    = "${var.account_name}-ebs-encryption"
      Purpose = "ebs-encryption"
    }
  )
}

resource "aws_kms_alias" "ebs" {
  name          = "alias/${var.account_name}-ebs"
  target_key_id = aws_kms_key.ebs.key_id
}

# KMS key for CloudWatch Logs encryption
resource "aws_kms_key" "cloudwatch_logs" {
  description             = "KMS key for CloudWatch Logs encryption in ${var.account_name}"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = var.enable_kms_key_rotation

  # Allow CloudWatch Logs to use this key
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${local.region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${local.region}:${local.account_id}:log-group:*"
          }
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name    = "${var.account_name}-cloudwatch-logs"
      Purpose = "cloudwatch-logs-encryption"
    }
  )
}

resource "aws_kms_alias" "cloudwatch_logs" {
  name          = "alias/${var.account_name}-cloudwatch-logs"
  target_key_id = aws_kms_key.cloudwatch_logs.key_id
}

# KMS key for VPC Flow Logs encryption
resource "aws_kms_key" "flow_logs" {
  description             = "KMS key for VPC Flow Logs encryption in ${var.account_name}"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = var.enable_kms_key_rotation

  # Allow VPC Flow Logs to use this key
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow VPC Flow Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${local.region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/vpc/flowlogs/*"
          }
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name    = "${var.account_name}-flow-logs"
      Purpose = "flow-logs-encryption"
    }
  )
}

resource "aws_kms_alias" "flow_logs" {
  name          = "alias/${var.account_name}-flow-logs"
  target_key_id = aws_kms_key.flow_logs.key_id
}

# KMS key for general data encryption (S3, RDS, etc.)
resource "aws_kms_key" "data" {
  description             = "KMS key for data encryption (S3, RDS, EFS, etc.) in ${var.account_name}"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = var.enable_kms_key_rotation

  # Allow cross-account access from logging account for S3 bucket encryption
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow S3 to use the key"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow logging account to read encrypted logs"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.logging_account_id}:root"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name    = "${var.account_name}-data"
      Purpose = "data-encryption"
    }
  )
}

resource "aws_kms_alias" "data" {
  name          = "alias/${var.account_name}-data"
  target_key_id = aws_kms_key.data.key_id
}
