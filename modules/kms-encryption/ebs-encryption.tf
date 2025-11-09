# Enable EBS encryption by default
resource "aws_ebs_encryption_by_default" "main" {
  enabled = var.enable_ebs_encryption_by_default
}

# Set the default KMS key for EBS encryption
resource "aws_ebs_default_kms_key" "main" {
  key_arn = aws_kms_key.ebs.arn

  depends_on = [aws_ebs_encryption_by_default.main]
}
