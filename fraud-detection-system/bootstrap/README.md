# Bootstrap Module - Infrastructure Setup

This Terraform module bootstraps the AWS infrastructure for GitHub Actions CI/CD with OIDC.

## What This Does

- ✅ Creates AWS OIDC provider for GitHub Actions
- ✅ Creates IAM role for GitHub Actions with proper trust policy
- ✅ Creates S3 bucket for Terraform state (with encryption, versioning, locking)
- ✅ Creates DynamoDB table for Terraform state locking
- ✅ Outputs values needed for GitHub secrets configuration

## Architecture

```
GitHub Actions
    ↓
[OIDC Provider] (this module creates this)
    ↓
[IAM Role] (this module creates this)
    ↓
[S3 + DynamoDB] (this module creates this)
    ↓
Main Terraform runs with OIDC credentials
```

## Prerequisites

```bash
# AWS CLI must be configured with credentials
aws configure

# For initial bootstrap only - temporary credentials with these permissions:
# - iam:CreateOpenIDConnectProvider
# - iam:CreateRole
# - iam:PutRolePolicy
# - s3:CreateBucket
# - dynamodb:CreateTable
```

## Usage

### Step 1: Initialize Bootstrap

```bash
cd bootstrap
terraform init
```

### Step 2: Review Plan

```bash
terraform plan -out=bootstrap.tfplan
```

### Step 3: Apply Bootstrap

```bash
terraform apply bootstrap.tfplan
```

This creates:
- OIDC provider: `arn:aws:iam::ACCOUNT:oidc-provider/token.actions.githubusercontent.com`
- IAM Role: `github-actions-fraud-detection`
- S3 Bucket: `fraud-detection-terraform-state-ACCOUNT_ID`
- DynamoDB Table: `terraform-locks`

### Step 4: Configure GitHub Secrets

Copy these values from the Terraform outputs:

```
GitHub Settings → Secrets and variables → Actions

AWS_ROLE_ARN = (from terraform output)
AWS_REGION = us-west-2
SLACK_WEBHOOK_URL = (optional)
```

### Step 5: Push to GitHub

```bash
git add .
git commit -m "feat: Add infrastructure bootstrap and CI/CD"
git push origin main
```

### Step 6: Deploy Main Infrastructure

After GitHub secrets are configured, the main workflows will run automatically.

## Files

- `main.tf` - OIDC provider, IAM role, S3, DynamoDB
- `variables.tf` - Configurable inputs
- `outputs.tf` - Values for GitHub secrets
- `locals.tf` - Helper variables

## Subsequent Deployments

After the bootstrap is complete, you can use GitHub Actions for all future infrastructure changes:

```bash
# Any changes to infrastructure/ trigger automated plan/apply
git add infrastructure/
git commit -m "infra: Update infrastructure"
git push origin main

# GitHub Actions terraform-apply workflow runs automatically on merge
```

## Destroying Bootstrap

⚠️ **Warning**: Removing bootstrap will remove OIDC and S3 state bucket!

```bash
# Only do this if you're completely removing the project
terraform destroy
```

## Troubleshooting

**Error: ThumbprintValidationError**
- GitHub's certificate thumbprint is: `6d4b1018202e31b925e63d821425301b7d8e4dd2`
- If this error occurs, update `locals.tf` with the current thumbprint

**Error: Role already exists**
- Run: `terraform import aws_iam_role.github_actions github-actions-fraud-detection`

**Error: S3 bucket already exists**
- Bucket names must be globally unique
- Update `locals.tf` to change the bucket naming scheme

## Cost

Estimated monthly cost:
- OIDC Provider: Free
- IAM Role: Free
- S3 Bucket: ~$0.50 (100 MB state files, minimal storage)
- DynamoDB: ~$0.25 (on-demand, minimal usage)

**Total: ~$1/month**

## Security Best Practices

✅ OIDC Provider limits GitHub Actions to specific repos/branches
✅ S3 bucket encrypted at rest (AES-256)
✅ S3 bucket versioning enabled for rollback capability
✅ DynamoDB for state locking (prevents concurrent modifications)
✅ Public access blocked on S3 bucket
✅ No long-lived AWS credentials needed
✅ All changes logged in CloudTrail

## Next Steps

1. Run bootstrap: `terraform apply`
2. Configure GitHub secrets
3. Push to GitHub
4. Main infrastructure deploys automatically
