# AWS Secure Landing Zone

A collection of Terraform modules that provide a sensible security baseline for new AWS accounts. This covers the essentials: centralized logging, encryption at rest, and preventive guardrails - all designed for a multi-account setup with UK data residency (eu-west-2).

## What's Included

This baseline implements four core security controls:

**A. Centralized Logging** - CloudTrail for API auditing, GuardDuty for threat detection, and VPC Flow Logs for network visibility. Everything's encrypted and sent to a central S3 bucket.

**B. Encryption at Rest** - Four customer-managed KMS keys (one each for EBS, CloudWatch Logs, VPC Flow Logs, and general data). EBS encryption is enabled by default across the account, so you can't accidentally create unencrypted volumes.

**C. Tagging Enforcement** - AWS Config rules that check for required tags on resources. Not as strict as Tag Policies (which block creation), but gives you visibility into what's compliant.

**D. Service Control Policies** - Five preventive guardrails that stop bad things from happening: no deleting CloudTrail, no public S3 buckets, encryption required, resources locked to London (eu-west-2), and KMS key protection.

## Quick Start

**Want to test it out?** There's a demo deployment that applies everything to a single account:

```bash
cd demo
terraform init
terraform plan
terraform apply
```

This creates all the security controls in your AWS account. It's self-contained and easy to tear down. See [demo/README.md](demo/README.md) for the full walkthrough.

**For production use**, you'll want to deploy the baseline to each account in your organization:

```hcl
module "account_baseline" {
  source = "./modules/account-baseline"

  account_name               = "my-account"
  environment                = "prod"
  logging_account_id         = "123456789012"
  central_logging_bucket_arn = "arn:aws:s3:::central-logs"

  # Required tags for this account
  required_tags = {
    Environment = "prod"
    Team        = "platform"
    CostCenter  = "engineering"
  }
}
```

You can also deploy modules individually if you need more granular control - each module has its own README with examples.

The SCPs need to be applied at the AWS Organization level, not per-account. See `/scps/` for the policies and how to apply them.

## Repository Structure

```
.
├── demo/                       # Single-account demo deployment
├── modules/
│   ├── account-baseline/       # Wrapper: all modules combined
│   ├── centralized-logging/   # CloudTrail, GuardDuty, VPC Flow Logs
│   ├── kms-encryption/         # 4 KMS keys + EBS encryption
│   └── tagging-enforcement/    # AWS Config rules
├── scps/                       # 5 Service Control Policies
├── diagrams/                   # Architecture diagrams
├── screenshots/                # Deployment evidence
└── REPORT.md                   # Technical summary
```

## Architecture

The full setup uses cross-account logging (everything goes to a central S3 bucket), KMS encryption for data at rest, and SCPs as preventive controls. I've put together some diagrams showing how it all fits together in `/diagrams/architecture.md`.

## Cost

Expect around **$32-124 per account per month**, depending on how much activity you've got:
- CloudTrail: $5-10 (pretty consistent)
- GuardDuty: $5-50 (scales with API volume)
- VPC Flow Logs: $10-50 (scales with traffic)
- KMS (4 keys): $4 (fixed cost)
- Config: $8-10 (scales with resources tracked)

## Documentation

Each component has its own README with usage examples and details:

- **[demo/README.md](demo/README.md)** - How to deploy the demo
- **[REPORT.md](REPORT.md)** - Technical writeup covering design decisions and trade-offs
- **`/modules/*/README.md`** - Detailed docs for each module
- **`/scps/README.md`** - Guide to the Service Control Policies
- **`/diagrams/architecture.md`** - Architecture diagrams and data flows

---

**Time spent:** ~7 hours  
**Author:** Finlay Wright  
**Submission:** AISI Product / Platform Security Challenge
