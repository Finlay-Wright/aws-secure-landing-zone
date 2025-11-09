# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Local variables
locals {
  account_id      = data.aws_caller_identity.current.account_id
  region          = data.aws_region.current.name
  cloudtrail_name = var.cloudtrail_name != null ? var.cloudtrail_name : "${var.account_name}-cloudtrail"

  common_tags = merge(
    var.tags,
    {
      Module = "centralized-logging"
    }
  )
}
