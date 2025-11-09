# VPC Flow Logs for default VPC
data "aws_vpc" "default" {
  count   = var.enable_default_vpc_flow_logs ? 1 : 0
  default = true
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  count             = var.enable_default_vpc_flow_logs ? 1 : 0
  name              = "/aws/vpc/flowlogs/${var.account_name}-default-vpc"
  retention_in_days = var.flow_logs_retention_days
  kms_key_id        = var.flow_logs_kms_key_arn

  tags = merge(
    local.common_tags,
    {
      Name    = "${var.account_name}-default-vpc-flow-logs"
      Purpose = "flow-logs"
    }
  )
}

# IAM role for VPC Flow Logs
resource "aws_iam_role" "flow_logs" {
  count = var.enable_default_vpc_flow_logs ? 1 : 0
  name  = "${var.account_name}-vpc-flow-logs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM policy for VPC Flow Logs
resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_default_vpc_flow_logs ? 1 : 0
  name  = "flow-logs-policy"
  role  = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# VPC Flow Log
resource "aws_flow_log" "default_vpc" {
  count                    = var.enable_default_vpc_flow_logs ? 1 : 0
  iam_role_arn             = aws_iam_role.flow_logs[0].arn
  log_destination          = aws_cloudwatch_log_group.flow_logs[0].arn
  traffic_type             = "ALL"
  vpc_id                   = data.aws_vpc.default[0].id
  max_aggregation_interval = 60

  tags = merge(
    local.common_tags,
    {
      Name    = "${var.account_name}-default-vpc-flow-log"
      Purpose = "network-monitoring"
    }
  )
}
