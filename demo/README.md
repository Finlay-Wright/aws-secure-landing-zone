# Demo Deployment

Quick single-account deployment for testing the baseline modules. **Not for production use.**

## What This Does

Deploys all three security modules in a single AWS account:
- KMS encryption (4 keys + EBS default encryption)
- Centralized logging (CloudTrail, GuardDuty, VPC Flow Logs)
- Tagging enforcement (Config rules)

In production, you'd have separate logging/security accounts. This uses the same account for everything to simplify testing.

## Prerequisites

- AWS account with admin permissions
- Terraform >= 1.5.0
- AWS CLI configured (`aws configure`)
- Default VPC in eu-west-2 (or it'll be created)

## Quick Start

```bash
# Initialize
terraform init

# Review what will be created (~30 resources)
terraform plan

# Deploy (takes ~5-10 minutes)
terraform apply

# When done testing, clean up
terraform destroy
```

## What Gets Created

- S3 bucket for "central" logging (simulates multi-account setup)
- 4 KMS keys with rotation enabled
- CloudTrail trail with CloudWatch integration
- GuardDuty detector with all data sources
- VPC Flow Logs for default VPC (if exists)
- 3 Config rules for tag enforcement

## Cost Warning

Running this demo costs approximately:
- **First 30 days**: ~$50-80 (includes free tiers)
- **After free tier**: ~$60-120/month

Key costs: KMS ($16), GuardDuty ($10-40), Flow Logs ($15-40), Config ($8-10)

**Important:** Run `terraform destroy` when done to avoid ongoing charges.

## Testing the Controls

**Verify EBS encryption is on:**
```bash
aws ec2 get-ebs-encryption-by-default --region eu-west-2
# Should return: "EbsEncryptionByDefault": true
```

**Check CloudTrail is logging:**
```bash
aws cloudtrail get-trail-status --name demo-baseline-trail --region eu-west-2
# Should return: "IsLogging": true
```

**View GuardDuty findings:**
```bash
# Generate sample finding (harmless test)
DETECTOR_ID=$(terraform output -raw guardduty_detector_id)
aws guardduty create-sample-findings --detector-id $DETECTOR_ID --finding-types Backdoor:EC2/DenialOfService.Tcp --region eu-west-2
```

**Check tag compliance:**
Go to AWS Config console → Rules → Look for "required-tag-*" rules

## Differences from Production

| Feature | Demo | Production |
|---------|------|------------|
| Logging account | Same account | Separate account |
| Central S3 bucket | Created here | Pre-existing |
| SCPs | Not applied | Applied at OU level |
| Region | eu-west-2 only | Multi-region trail |
| Config recorder | Must exist | Included in baseline |

## Troubleshooting

**No default VPC:**
VPC Flow Logs will fail. Either create a default VPC or set `enable_default_vpc_flow_logs = false` in the logging module.

**Config recorder doesn't exist:**
Tagging module will fail. Enable AWS Config first:
```bash
aws configservice put-configuration-recorder --configuration-recorder name=default,roleARN=arn:aws:iam::ACCOUNT:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig --region eu-west-2
aws configservice put-delivery-channel --delivery-channel name=default,s3BucketName=YOUR-BUCKET --region eu-west-2
aws configservice start-configuration-recorder --configuration-recorder-name default --region eu-west-2
```

**Access Denied errors:**
Make sure your AWS credentials have administrator permissions.

## Next Steps

After testing here, deploy to a real multi-account setup using `/examples/complete/`.
