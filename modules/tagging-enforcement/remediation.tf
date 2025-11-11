# Auto-tagging remediation Lambda and supporting infrastructure
# This is triggered by Config compliance changes to automatically tag non-compliant resources

# Package Lambda function
data "archive_file" "remediation_lambda" {
  count       = var.enable_auto_remediation ? 1 : 0
  type        = "zip"
  source_file = "${path.module}/lambda/auto_tag_remediation.py"
  output_path = "${path.module}/lambda/auto_tag_remediation.zip"
}

# IAM role for Lambda
resource "aws_iam_role" "remediation_lambda" {
  count = var.enable_auto_remediation ? 1 : 0
  name  = "${var.account_name}-${var.environment}-tag-remediation-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "Tag Remediation Lambda Role"
    }
  )
}

# IAM policy for Lambda - allow tagging operations
resource "aws_iam_role_policy" "remediation_lambda" {
  count = var.enable_auto_remediation ? 1 : 0
  name  = "tag-remediation-permissions"
  role  = aws_iam_role.remediation_lambda[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowResourceTagging"
        Effect = "Allow"
        Action = [
          "tag:GetResources",
          "tag:TagResources",
          "tag:UntagResources"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowConfigRead"
        Effect = "Allow"
        Action = [
          "config:DescribeConfigRules",
          "config:GetComplianceDetailsByConfigRule"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowSSMParameterRead"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/baseline/*"
      },
      {
        Sid    = "AllowSNSPublish"
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = var.remediation_sns_topic_arn != "" ? var.remediation_sns_topic_arn : "*"
      }
    ]
  })
}

# Attach AWS managed policy for Lambda basic execution
resource "aws_iam_role_policy_attachment" "remediation_lambda_basic" {
  count      = var.enable_auto_remediation ? 1 : 0
  role       = aws_iam_role.remediation_lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda function
resource "aws_lambda_function" "tag_remediation" {
  count            = var.enable_auto_remediation ? 1 : 0
  filename         = data.archive_file.remediation_lambda[0].output_path
  function_name    = "${var.account_name}-${var.environment}-tag-remediation"
  role             = aws_iam_role.remediation_lambda[0].arn
  handler          = "auto_tag_remediation.lambda_handler"
  source_code_hash = data.archive_file.remediation_lambda[0].output_base64sha256
  runtime          = "python3.11"
  timeout          = 60
  memory_size      = 256

  environment {
    variables = {
      ENVIRONMENT                = var.environment
      DEFAULT_TAGS_SSM_PARAMETER = "/baseline/default-tags"
      SNS_TOPIC_ARN              = var.remediation_sns_topic_arn
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "Tag Remediation Lambda"
    }
  )
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "remediation_lambda" {
  count             = var.enable_auto_remediation ? 1 : 0
  name              = "/aws/lambda/${aws_lambda_function.tag_remediation[0].function_name}"
  retention_in_days = 30

  tags = var.tags
}

# EventBridge rule to trigger Lambda on Config compliance changes
resource "aws_cloudwatch_event_rule" "config_compliance_change" {
  count       = var.enable_auto_remediation ? 1 : 0
  name        = "${var.account_name}-${var.environment}-config-compliance-change"
  description = "Trigger tag remediation on Config compliance changes"

  event_pattern = jsonencode({
    source      = ["aws.config"]
    detail-type = ["Config Rules Compliance Change"]
    detail = {
      messageType = ["ComplianceChangeNotification"]
      newEvaluationResult = {
        complianceType = ["NON_COMPLIANT"]
      }
      configRuleName = [
        for tag_key in var.required_tag_keys : "required-tag-${lower(tag_key)}"
      ]
    }
  })

  tags = var.tags
}

# EventBridge target - invoke Lambda
resource "aws_cloudwatch_event_target" "remediation_lambda" {
  count = var.enable_auto_remediation ? 1 : 0
  rule  = aws_cloudwatch_event_rule.config_compliance_change[0].name
  arn   = aws_lambda_function.tag_remediation[0].arn
}

# Lambda permission for EventBridge
resource "aws_lambda_permission" "allow_eventbridge" {
  count         = var.enable_auto_remediation ? 1 : 0
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tag_remediation[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.config_compliance_change[0].arn
}

# Optional: SSM Parameter for default tags (users can populate this)
resource "aws_ssm_parameter" "default_tags" {
  count = var.enable_auto_remediation && var.create_default_tags_parameter ? 1 : 0
  name  = "/baseline/default-tags"
  type  = "String"
  value = jsonencode(var.required_tags)

  description = "Default tags applied by auto-remediation Lambda"

  tags = var.tags
}
