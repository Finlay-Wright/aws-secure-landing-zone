# AWS Secure Landing Zone

Terraform modules for securing AWS accounts with centralized logging, encryption, and compliance controls. Built for AISI's multi-account environment with UK data residency.

## What's Included

**Deliverable A: Centralized Logging**
- CloudTrail (multi-region, log validation, encrypted)
- GuardDuty threat detection
- VPC Flow Logs to CloudWatch

**Deliverable B: KMS Encryption**
- 4 dedicated KMS keys (EBS, CloudWatch Logs, VPC Flow Logs, Data)
- EBS encryption enabled by default
- Automatic key rotation

**Deliverable C: Tagging Enforcement**
- AWS Config rules for required tags
- Compliance dashboard

**Deliverable D: Service Control Policies**
- Prevent CloudTrail deletion
- Block public S3 buckets
- Require encryption
- Restrict to eu-west-2 (London)
- Protect KMS keys

## Quick Start

**Demo deployment (single account):**

```bash
cd demo
terraform init
terraform plan
terraform apply
```

Deploys all security controls to one AWS account for testing. See [demo/README.md](demo/README.md) for details.

**Production deployment (multi-account):**

Deploy modules individually to each account:

```hcl
module "kms_encryption" {
  source             = "./modules/kms-encryption"
  account_name       = "my-account"
  environment        = "prod"
  logging_account_id = "123456789012"
}

module "centralized_logging" {
  source                      = "./modules/centralized-logging"
  account_name                = "my-account"
  environment                 = "prod"
  logging_account_id          = "123456789012"
  central_logging_bucket_arn  = "arn:aws:s3:::central-logs"
  cloudwatch_logs_kms_key_arn = module.kms_encryption.cloudwatch_logs_key_arn
  flow_logs_kms_key_arn       = module.kms_encryption.flow_logs_key_arn
}

module "tagging_enforcement" {
  source            = "./modules/tagging-enforcement"
  account_name      = "my-account"
  environment       = "prod"
  required_tag_keys = ["Project", "Team", "CostCenter"]
}
```

Then apply SCPs at AWS Organization level (see `/scps/`).

## Repository Structure

```
.
├── demo/                       # Single-account demo deployment
├── modules/
│   ├── centralized-logging/   # CloudTrail, GuardDuty, VPC Flow Logs
│   ├── kms-encryption/         # 4 KMS keys + EBS encryption
│   └── tagging-enforcement/    # AWS Config rules
├── scps/                       # 5 Service Control Policies
├── diagrams/                   # Architecture diagrams
├── screenshots/                # Deployment evidence
└── REPORT.md                   # Technical summary
```

## Architecture

Cross-account logging with KMS encryption and SCPs. Full diagrams in `/diagrams/architecture.md`.

## Cost

Per-account: **$44-146/month**
- CloudTrail: $5-10
- GuardDuty: $5-50
- VPC Flow Logs: $10-50
- KMS (4 keys): $16
- Config: $8-10

## Documentation

- **[demo/README.md](demo/README.md)** - Single-account deployment
- **[REPORT.md](REPORT.md)** - Technical summary
- **`/modules/*/README.md`** - Module documentation
- **`/scps/README.md`** - SCP guide
- **`/diagrams/architecture.md`** - Architecture diagrams

## TODO

- [ ] Deploy demo and take screenshots
- [ ] Convert REPORT.md to PDF

---

**Time spent:** ~7 hours  
**Author:** Finlay Wright  
**Submission:** AISI Product / Platform Security Challenge
