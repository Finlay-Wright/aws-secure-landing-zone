# Demo Deployment

Quick single-account deployment for testing the baseline modules. **Not for production use.**

## What This Does

Deploys all three security modules in a single AWS account:
- KMS encryption (4 keys + EBS default encryption)
- Centralized logging (CloudTrail, GuardDuty, VPC Flow Logs)
- Tagging enforcement (Config rules)

In production, you'd have separate logging/security accounts. This uses the same account for everything to simplify testing.