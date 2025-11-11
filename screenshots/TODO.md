# Screenshots TODO

## Setup

- [ ] Configure AWS credentials for your demo account
  ```bash
  export AWS_PROFILE=your-profile-name
  # or use: aws configure
  ```

- [ ] Deploy single-account demo baseline
  ```bash
  cd demo
  terraform init
  terraform plan
  terraform apply -auto-approve
  ```
  
  ⏱️ **Deployment time: ~5-10 minutes**

## Screenshots to Capture

### Essential (5 screenshots minimum)

- [ ] **01-terraform-apply.png**
  - Terminal showing successful `terraform apply` output
  - Should show all modules created (logging, KMS, tagging)
  - Capture the final "Apply complete! Resources: X added" message

- [ ] **02-cloudtrail.png**
  - AWS Console → CloudTrail → Trails
  - Show trail is enabled, multi-region
  - Highlight: S3 destination, KMS encryption enabled

- [ ] **03-kms-keys.png**
  - AWS Console → KMS → Customer managed keys
  - Show all 4 keys: ebs, cloudwatch-logs, vpc-flow-logs, data
  - Filter to eu-west-2 region

- [ ] **04-guardduty.png**
  - AWS Console → GuardDuty → Summary
  - Show GuardDuty is enabled
  - Any findings (if available)

- [ ] **05-config-rules.png**
  - AWS Console → Config → Rules
  - Show required-tags rule
  - Compliance status (compliant/non-compliant count)

### Nice-to-Have (3 additional screenshots)

- [ ] **06-ebs-encryption.png**
  - AWS Console → EC2 → Settings → EBS encryption
  - Show "Always encrypt new EBS volumes" enabled
  - Show custom KMS key selected

- [ ] **07-vpc-flow-logs.png**
  - AWS Console → VPC → Your VPCs → Flow logs tab
  - Show flow logs active and sending to CloudWatch
  - (Only if you have a default VPC - most accounts do)

- [ ] **08-terraform-plan.png**
  - Screenshot of initial `terraform plan` output
  - Shows what will be created

## Annotation

- [ ] Add arrows/highlights to key information using:
  - Mac Preview (Tools → Annotate)
  - Or Skitch
  - Or any screenshot tool with basic markup

- [ ] Ensure all screenshots show:
  - Region (eu-west-2) visible in top-right
  - Account ID partially visible (can blur for privacy)
  - Timestamp/date visible if possible

## Documentation

- [ ] Create `screenshots/README.md` with brief description of each screenshot
- [ ] Add 1-2 key screenshots to main README.md
- [ ] Reference screenshots folder in REPORT.md

## Cleanup

⚠️ **Important: Don't forget to destroy resources after screenshots!**

```bash
cd demo
terraform destroy -auto-approve
```

This will remove all resources and stop charges.

## Time Budget

⏱️ **Total: 30-45 minutes**
- Deploy: 10 mins
- Screenshots: 15 mins
- Annotation: 10 mins
- Documentation: 10 mins

## Notes

- This uses a single account for demo purposes only
- SCPs are NOT deployed (they require AWS Organizations)
- The demo creates a mock central logging bucket in the same account
- Cost while running: ~$0.04/hour
