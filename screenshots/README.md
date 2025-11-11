# Deployment Screenshots

These screenshots show a successful deployment of the baseline in a test AWS account (eu-west-2 region). I've deployed the demo project to verify everything works as expected.

## What's Captured

### 01-terraform-apply.png
The full Terraform apply output. You can see all 32 resources being created - KMS keys, CloudTrail, GuardDuty, VPC Flow Logs, and the Config rules. This took about 2-3 minutes to deploy.

### 02-cloudtrail.png
CloudTrail is configured as a multi-region trail that captures all API activity. It's sending logs to the central S3 bucket and encrypting them with the dedicated KMS key. Log file validation is turned on for tamper detection.

### 03-kms-keys.png
The four customer-managed KMS keys: one for EBS volumes, one for CloudWatch Logs, one for VPC Flow Logs, and one for general data (S3, RDS, etc.). All of them have automatic annual rotation enabled.

### 04-guard-duty.png
GuardDuty is running with all data sources enabled - VPC Flow Logs, CloudTrail logs, and DNS logs. It'll flag suspicious activity like unusual API calls or potential crypto mining.

### 05-config-rules.png
The AWS Config rules checking for required tags (Project, Team, Environment). In this screenshot you can see the compliance status - any resources missing tags show up as non-compliant here.

### 06-ebs-encryption.png
EBS encryption by default is enabled account-wide. From this point on, you can't create an unencrypted EBS volume even if you try - AWS will automatically encrypt it with the KMS key.

### 07-vpc-flow-logs.png
VPC Flow Logs capturing network traffic metadata from the default VPC. These logs go to CloudWatch and are encrypted with the VPC Flow Logs KMS key. Useful for troubleshooting connectivity and spotting unusual traffic patterns.
