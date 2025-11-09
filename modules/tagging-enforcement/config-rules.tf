# AWS Config Rule: Require tags on resources
resource "aws_config_config_rule" "required_tags" {
  for_each = var.enable_config_rules ? toset(var.required_tag_keys) : []

  name        = "required-tag-${lower(each.value)}"
  description = "Checks whether resources are tagged with the ${each.value} tag"

  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }

  input_parameters = jsonencode({
    tag1Key = each.value
  })

  scope {
    compliance_resource_types = var.resource_types
  }

  tags = merge(
    local.common_tags,
    {
      Name    = "required-tag-${lower(each.value)}"
      Purpose = "tag-enforcement"
    }
  )
}

# AWS Config Rule: Check tag values match expected
# This checks if tags have the correct values for this environment
resource "aws_config_config_rule" "tag_values" {
  count = var.enable_config_rules ? 1 : 0

  name        = "${var.account_name}-tag-value-compliance"
  description = "Checks whether resources have the correct tag values for ${var.environment} environment"

  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }

  input_parameters = jsonencode({
    tag1Key   = "Environment"
    tag1Value = var.required_tags["Environment"]
  })

  scope {
    compliance_resource_types = var.resource_types
  }

  tags = merge(
    local.common_tags,
    {
      Name    = "${var.account_name}-tag-value-compliance"
      Purpose = "tag-value-enforcement"
    }
  )

  depends_on = [aws_config_config_rule.required_tags]
}
