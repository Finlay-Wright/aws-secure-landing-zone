# Service Control Policies (SCPs)

**Deliverable D** - Organization-level preventive controls.

## Overview

SCPs deny actions at the AWS Organizations level before they execute, regardless of IAM policies. Even account admins can't bypass them.

**Why:** IAM policies can be changed by admins. SCPs stop risky actions at the API level - can't disable CloudTrail to hide tracks, can't make S3 buckets public, can't create unencrypted storage.

## Included Policies

### deny-cloudtrail-delete.json

Blocks:
- `cloudtrail:DeleteTrail`
- `cloudtrail:StopLogging`
- `cloudtrail:UpdateTrail` (disabling log validation)

Exception for break-glass roles (customize ARNs as needed).

### deny-public-s3.json

Blocks:
- Public ACLs (public-read, public-read-write)
- Bucket policies without SSL/TLS
- Disabling S3 Block Public Access

Public S3 buckets = #1 cause of data breaches.

### require-encryption.json

Blocks creating unencrypted:
- S3 uploads without SSE
- EBS volumes
- RDS instances/clusters
- DynamoDB tables
- EFS file systems

Must encrypt at creation for some services (RDS), so preventive control is critical.

### restrict-regions.json

Only allows resources in EU (London) region (eu-west-2).

Exceptions for global services (IAM, CloudFront, Route53).

**Why eu-west-2:** UK data residency requirements for AISI (UK government agency).

### protect-kms-keys.json

Blocks:
- Disabling/deleting log encryption keys
- Scheduling key deletion with < 30 days
- Modifying key policies on log keys

Prevents denial of service on logging and key deletion to cover tracks.

## Usage

Apply at the Organization or OU level (not managed by this Terraform code):

```bash
# Create policy
aws organizations create-policy \
  --name DenyCloudTrailDelete \
  --type SERVICE_CONTROL_POLICY \
  --content file://deny-cloudtrail-delete.json

# Attach to OU
aws organizations attach-policy \
  --policy-id p-xxxxxxxxx \
  --target-id ou-xxxx-xxxxxxxx
```

**Test in dev first.** Apply to dev OU before production.

## Rollout Order

Least to most disruptive:
1. restrict-regions (low risk)
2. deny-cloudtrail-delete (low risk)
3. protect-kms-keys (low risk)
4. deny-public-s3 (medium risk)
5. require-encryption (high risk - may break existing stuff)

## Customization Needed

- Update exception role ARNs in deny-cloudtrail-delete.json and protect-kms-keys.json
- Change allowed regions in restrict-regions.json
- Review resource types in require-encryption.json

## Testing

Try the blocked action after applying. Should get AccessDenied even with IAM policy allowing it.

## Exception Handling

Add exception roles to policies or temporarily detach for emergencies. Track exceptions.

## Notes

- Free (no cost for SCPs)
- Only work with AWS Organizations
- Can only deny, not grant permissions
- Some services don't fully support SCP conditions

