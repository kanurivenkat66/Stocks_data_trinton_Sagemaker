# CI/CD Pipeline - GitHub Actions + AWS

This directory contains all files needed to set up and manage the continuous integration and deployment pipeline for the fraud detection system.

## 📁 Directory Contents

### Configuration Files

- **`github-actions-policy.json`** - IAM policy with Terraform execution permissions
- **`github-oidc-trust-policy.json`** - OIDC trust policy for GitHub Actions
- **`GITHUB_ACTIONS_REFERENCE.md`** - Comprehensive workflow documentation

### Setup Scripts

- **`setup_github_oidc.sh`** - Automated AWS OIDC and IAM role setup
  - Creates OIDC provider for GitHub Actions
  - Creates IAM role with Terraform permissions
  - Sets up S3 state bucket
  - Creates DynamoDB lock table
  - Usage: `./setup_github_oidc.sh --github-org YOUR_ORG --github-repo YOUR_REPO`

### Documentation

- **`CI_CD_SETUP_GUIDE.md`** - Complete setup and deployment guide
- This README.md

### GitHub Actions Workflows (in `.github/workflows/`)

- **`terraform.yml`** - Infrastructure deployment pipeline
- **`ml-pipeline.yml`** - Model training and deployment
- **`setup.yml`** - CI/CD setup verification and documentation

---

## 🚀 Quick Start

### 1. Run AWS Setup

```bash
cd cicd
chmod +x setup_github_oidc.sh

./setup_github_oidc.sh \
  --github-org your-github-username \
  --github-repo your-repo-name
```

This will:
- ✅ Create OIDC provider
- ✅ Create IAM role with permissions
- ✅ Set up S3 backend bucket
- ✅ Configure DynamoDB state locks
- ✅ Output secrets for GitHub

### 2. Configure GitHub Secrets

1. Go to repository **Settings → Secrets and variables → Actions**
2. Create secrets from the setup script output:
   - `AWS_ROLE_ARN`
   - `AWS_ACCOUNT_ID`

### 3. Generate Infrastructure Config

```bash
cd ../infrastructure
./setup.sh

# Generates terraform.tfvars with your configuration
```

### 4. Deploy via Pull Request

```bash
# Create feature branch
git checkout -b infrastructure/first-deploy

# Commit configuration
git add terraform.tfvars
git commit -m "Initial infrastructure configuration"
git push origin infrastructure/first-deploy

# Create Pull Request on GitHub
# Review terraform plan in PR comment
# Merge to main to trigger deployment
```

---

## 📋 Workflow Triggers

### Infrastructure Deployment (terraform.yml)

**Automatic Triggers**:
- Push to main branch (applies terraform)
- Pull Request to main (shows terraform plan)

**Manual Trigger**:
```bash
gh workflow run terraform.yml \
  --ref main \
  -f action=plan  # or 'apply' or 'destroy'
```

### Model Training (ml-pipeline.yml)

**Automatic Triggers**:
- Weekly schedule (Sunday 2 AM UTC)

**Manual Trigger**:
```bash
gh workflow run ml-pipeline.yml \
  --ref main \
  -f data_source=generate \           # or 's3'
  -f deploy_model=true                 # or 'false'
```

### Setup & Documentation (setup.yml)

Generates setup guides, checklists, and GitHub Actions reference.

---

## 🔒 Security

### OIDC Authentication

Uses GitHub Actions OIDC federation instead of static credentials:
- No AWS credentials stored in GitHub
- Time-limited tokens (default 15 minutes)
- Specific repository and branch restrictions
- Automatic credential rotation

### IAM Permissions

The role has permissions for:
- EC2, EKS, AutoScaling
- S3, KMS, CloudWatch
- IAM role management
- SageMaker training

**Least Privilege**: For production, consider restricting to specific resource tags.

### Approval Gates

```
Pull Request → Code Review → Approval → Merge → Auto Deploy
```

Production deployments require:
- ✓ Terraform validation
- ✓ Security scan
- ✓ Manual approval
- ✓ Status checks passing

---

## 📊 Workflow Status

View pipeline execution:

```bash
# List recent runs
gh run list --workflow terraform.yml

# View specific run
gh run view RUN_ID

# Follow in real-time
gh run watch RUN_ID

# Download artifacts
gh run download RUN_ID -D artifacts/
```

---

## 🔧 Troubleshooting

### OIDC Authentication Fails

```bash
# Verify OIDC provider
aws iam list-open-id-connect-providers

# Check trust policy
aws iam get-role --role-name github-actions-fraud-detection
```

### Terraform State Lock

```bash
# Force unlock (use with caution)
aws dynamodb delete-item \
  --table-name terraform-locks \
  --key '{"LockID":{"S":"fraud-detection-terraform-state/prod/terraform.tfstate"}}'
```

### S3 Access Denied

1. Verify bucket policy allows the role
2. Check IAM role has S3 permissions
3. Verify encryption is AES256

---

## 📈 Monitoring

### GitHub Actions Dashboard

1. Go to Actions tab
2. Select workflow
3. View real-time logs and status

### AWS Console

1. CloudFormation - Stack events
2. CloudWatch - Logs and metrics
3. EKS - Cluster status
4. S3 - Model artifacts

### Command Line

```bash
# View Terraform apply output
gh run view RUN_ID --log | grep "Apply complete"

# Check deployment summary
gh run download RUN_ID -D artifacts/
cat artifacts/deployment-summary.md
```

---

## 📚 Complete Documentation

For detailed setup and troubleshooting, see: **`CI_CD_SETUP_GUIDE.md`**

Topics covered:
- Prerequisites and requirements
- Complete AWS setup walkthrough
- OIDC configuration details
- GitHub secrets and variables
- Workflow documentation
- Deployment procedures
- Monitoring and observability
- Security best practices
- Troubleshooting guide

---

## 🎯 Next Steps

1. **Run Setup**: `./setup_github_oidc.sh --github-org ORG --github-repo REPO`
2. **Configure Secrets**: Add outputs to GitHub
3. **Generate Config**: Run `../infrastructure/setup.sh`
4. **Deploy**: Push to main branch
5. **Monitor**: Watch Actions tab and AWS console
6. **Model Training**: Trigger ML pipeline workflow
7. **Observe**: Check Grafana dashboards

---

## 📞 Support

For issues or questions:

1. Check **CI_CD_SETUP_GUIDE.md** troubleshooting section
2. View workflow logs in GitHub Actions
3. Enable debug logging: `gh secret create ACTIONS_STEP_DEBUG --body true`
4. Check AWS CloudTrail for API errors
5. Review Terraform state with: `terraform state list`

---

## 📝 Files Reference

| File | Purpose |
|------|---------|
| `github-actions-policy.json` | IAM permissions for Terraform |
| `github-oidc-trust-policy.json` | OIDC trust relationship |
| `setup_github_oidc.sh` | Automated AWS setup |
| `CI_CD_SETUP_GUIDE.md` | Complete manual |
| `.github/workflows/terraform.yml` | Infrastructure CI/CD |
| `.github/workflows/ml-pipeline.yml` | Model training CI/CD |
| `.github/workflows/setup.yml` | Setup verification |

---

**Status**: ✅ Ready for deployment

**Last Updated**: 2024
**Version**: 1.0.0
