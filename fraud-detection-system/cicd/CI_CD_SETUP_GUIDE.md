# 🚀 CI/CD Pipeline Setup Guide

Complete guide to setting up automated infrastructure deployment with GitHub Actions and AWS.

## Quick Overview

**What you're setting up:**
- ✅ Automated Terraform validation & deployment
- ✅ Data pipeline orchestration
- ✅ Model training automation
- ✅ KServe model deployment
- ✅ Slack notifications
- ✅ Zero long-lived AWS credentials (OIDC)

---

## Prerequisites

### Required Tools

- **AWS CLI v2**: [Install Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- **Git**: Version control and GitHub integration
- **GitHub Account**: Repository access and Actions workflow management
- **Terraform**: For infrastructure-as-code (optional for CI/CD, installed in workflows)
- **kubectl**: For Kubernetes cluster management (optional, installed in workflows)

### AWS Account Requirements

- Active AWS account with appropriate IAM permissions
- Ability to create IAM roles, S3 buckets, and EC2/EKS resources
- No region restrictions (we default to us-west-2)

### GitHub Repository Setup

1. Fork or clone this repository
2. Ensure you have write access to repository settings
3. Access to Secrets and Variables configuration

---

## Quick Start

### Step 1: Prepare Your Environment

```bash
# Navigate to CI/CD directory
cd fraud-detection-system/cicd

# Export configuration
export GITHUB_ORG="your-github-org"
export GITHUB_REPO="your-repo-name"
```

### Step 2: Run AWS Setup

```bash
# Run the automated OIDC setup
./setup_github_oidc.sh \
  --github-org "$GITHUB_ORG" \
  --github-repo "$GITHUB_REPO"
```

This script will:
- Create OIDC provider if it doesn't exist
- Create IAM role for GitHub Actions
- Attach necessary permissions
- Create S3 bucket for Terraform state
- Create DynamoDB table for state locking

### Step 3: Configure GitHub Secrets

1. Go to your GitHub repository
2. Navigate to: **Settings → Secrets and variables → Actions**
3. Create repository secrets:
   - `AWS_ROLE_ARN`: From setup script output
   - `AWS_ACCOUNT_ID`: From setup script output

### Step 4: Generate Terraform Configuration

```bash
cd ../infrastructure

# Run interactive setup
./setup.sh

# This generates terraform.tfvars with your configuration
```

### Step 5: Deploy via GitHub Actions

1. Create a feature branch:
   ```bash
   git checkout -b infrastructure/initial-deploy
   ```

2. Commit configuration:
   ```bash
   git add terraform.tfvars
   git commit -m "Initial infrastructure configuration"
   git push origin infrastructure/initial-deploy
   ```

3. Create Pull Request on GitHub

4. Review `terraform plan` output in PR comment

5. Merge to main to trigger `terraform apply`

---

## AWS Setup

### OIDC Configuration

GitHub Actions authenticates with AWS using OIDC (OpenID Connect) federation instead of storing long-lived credentials.

#### Manual OIDC Setup (if automated script fails)

```bash
# 1. Create OIDC Provider
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list "6938fd4d98bab03faadb97b34396831e3780aea1" \
                   "1c58a3a8518e8759bf075b76b750d4f2df264fcd"

# 2. Get Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Account ID: $ACCOUNT_ID"

# 3. Create trust policy
cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::$ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_ORG/YOUR_REPO:ref:refs/heads/main"
        }
      }
    }
  ]
}
EOF

# 4. Create IAM role
aws iam create-role \
  --role-name github-actions-fraud-detection \
  --assume-role-policy-document file://trust-policy.json
```

### IAM Policy Configuration

The automated script attaches comprehensive permissions for:

- **EC2**: Full permissions for instance management
- **EKS**: Cluster creation and management
- **IAM**: Role and policy management
- **S3**: Bucket and object operations
- **CloudWatch**: Log management
- **AutoScaling**: Node and pod scaling
- **ElasticLoadBalancing**: Load balancer configuration
- **KMS**: Encryption key operations
- **SageMaker**: Model training and management

#### Least Privilege Alternative

For production environments, consider restricting permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeSecurityGroups",
        "ec2:RunInstances",
        "ec2:TerminateInstances"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/Environment": "fraud-detection"
        }
      }
    }
  ]
}
```

### Terraform State Backend

#### S3 + DynamoDB Setup

```bash
# Create S3 bucket
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET="fraud-detection-terraform-state-$ACCOUNT_ID"

aws s3api create-bucket \
  --bucket "$BUCKET" \
  --region us-west-2 \
  --create-bucket-configuration LocationConstraint=us-west-2

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

# Block public access
aws s3api put-public-access-block \
  --bucket "$BUCKET" \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

#### Update Terraform Backend

Edit `infrastructure/provider.tf`:

```hcl
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "fraud-detection-terraform-state-ACCOUNT_ID"
    key            = "prod/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

---

## GitHub Configuration

### 1. Repository Secrets

Navigate to: **Settings → Secrets and variables → Actions → New repository secret**

| Secret | Value | Description |
|--------|-------|-------------|
| `AWS_ROLE_ARN` | `arn:aws:iam::ACCOUNT:role/github-actions-fraud-detection` | IAM role for GitHub Actions |
| `AWS_ACCOUNT_ID` | `123456789012` | AWS account ID |

### 2. Environment Variables

Navigate to: **Settings → Secrets and variables → Actions → Variables**

| Variable | Value | Description |
|----------|-------|-------------|
| `AWS_REGION` | `us-west-2` | AWS region for deployment |
| `TF_VERSION` | `1.5.0` | Terraform version |
| `PYTHON_VERSION` | `3.10` | Python version for ML pipeline |

### 3. Branch Protection Rules

Protect main branch: **Settings → Branches → Add rule**

- **Branch name pattern**: `main`
- **Require a pull request before merging**: ✓
- **Require status checks to pass**: ✓
  - `validation`
  - `plan`
  - `security-scan`
- **Require branches to be up to date**: ✓
- **Require code reviews**: ✓ (at least 1 approver)
- **Dismiss stale pull request approvals**: ✓

### 4. Environment Protection

Create "production" environment: **Settings → Environments → New environment**

- **Environment name**: `production`
- **Deployment branches**: `main`
- **Required reviewers**: Select team members

---

## Workflow Documentation

### terraform.yml - Infrastructure Deployment

**Purpose**: Validate and deploy AWS infrastructure

**Triggers**:
- PR to main (runs terraform plan)
- Push to main (runs terraform apply + plan)
- Manual trigger (workflow_dispatch)

**Jobs**:

1. **validation**: Format and syntax checks
   - Runs: `terraform fmt` and `terraform validate`
   - Runs on every trigger
   - Must pass to proceed

2. **plan**: Generate terraform plan
   - Runs: `terraform init` and `terraform plan`
   - Triggered on: PRs only
   - Displays changes in PR comment
   - Includes cost estimation

3. **apply**: Apply terraform changes
   - Runs: `terraform apply tfplan`
   - Triggered on: Main branch merge
   - Requires manual approval for production
   - Creates deployment summary

4. **cost-estimate**: Calculate monthly costs
   - Estimates AWS resource costs
   - Posts estimate to PR comments

5. **security-scan**: Run security checks
   - Runs: `tfsec` and `terraform-compliance`
   - Checks for security misconfigurations
   - Non-blocking (informational)

**Artifacts**:
- `terraform-plan`: Binary plan file (5 days retention)
- `terraform-apply-output`: JSON outputs and logs (30 days)
- `deployment-summary`: Human-readable summary

### ml-pipeline.yml - Model Training & Deployment

**Purpose**: Train and deploy fraud detection model

**Triggers**:
- Manual workflow_dispatch with parameters
- Weekly schedule (Sunday 2 AM UTC)

**Parameters**:
- `data_source`: `generate` | `s3`
- `deploy_model`: Deploy to KServe (true | false)

**Jobs**:

1. **generate-data**: Create synthetic training data
   - Generates 100k transactions (configurable)
   - 5% fraud rate (realistic distribution)
   - Saves to local artifact

2. **preprocess-data**: Feature engineering
   - Cleaning and validation
   - Train/val/test splits (70/15/15)
   - Feature scaling and encoding

3. **train-model**: XGBoost training
   - GPU-accelerated training (if available)
   - Metrics: AUC, Precision, Recall, F1
   - Model validation (AUC > 0.75 threshold)

4. **export-to-onnx**: Convert to ONNX format
   - Cross-platform model format
   - ONNX validation
   - Triton server configuration

5. **upload-to-s3**: Push model to registry
   - Versioned model storage
   - Model registry JSON update
   - Latest model pointer

6. **deploy-model**: Update KServe service
   - Requires `deploy_model=true`
   - Applies manifest to cluster
   - Waits for pods to be ready

7. **test-inference**: Validate predictions
   - Test prediction endpoint
   - Benchmark latency/throughput
   - Results saved to artifacts

**Artifacts**:
- `training-data`: Raw CSV (5 days)
- `preprocessed-data`: Splits (5 days)
- `trained-model`: XGBoost binary (30 days)
- `onnx-model`: ONNX format (30 days)

### setup.yml - CI/CD Setup & Documentation

**Purpose**: Verify setup and generate documentation

**Jobs**:

1. **verify-setup**: Check prerequisites
   - AWS CLI availability
   - GitHub secrets configured
   - Terraform files present

2. **generate-setup-guide**: Create setup instructions
   - AWS IAM role creation steps
   - OIDC provider setup
   - GitHub secrets configuration

3. **safety-gates**: Configuration for approvals
   - Deployment approval processes
   - Rollback procedures
   - Environment protection

4. **documentation**: Generate reference guide
   - Workflow file documentation
   - Manual trigger examples
   - Debugging guide

---

## Deploying Infrastructure

### Via GitHub Web UI

#### Method 1: Pull Request Workflow (Recommended)

```bash
# 1. Create feature branch
git checkout -b infrastructure/add-monitoring

# 2. Make changes to infrastructure/variables.tf
# 3. Commit and push
git add infrastructure/variables.tf
git commit -m "Add CloudWatch monitoring"
git push origin infrastructure/add-monitoring

# 4. Create Pull Request on GitHub
# 5. GitHub Actions automatically runs terraform plan
# 6. Review plan output in PR comment
# 7. Request code review from team member
# 8. Merge to main (requires approval)
# 9. terraform apply runs automatically
```

#### Method 2: Manual Workflow Trigger

1. Go to **Actions** tab
2. Select **Terraform Infrastructure** workflow
3. Click **Run workflow**
4. Select action: `plan` or `apply`
5. Click **Run workflow**

### Via GitHub CLI

```bash
# List workflow files
gh workflow list

# Trigger terraform plan
gh workflow run terraform.yml \
  --ref main \
  -f action=plan

# Trigger terraform apply
gh workflow run terraform.yml \
  --ref main \
  -f action=apply

# Monitor execution
gh run watch

# View logs
gh run view RUN_ID --log

# Download artifacts
gh run download RUN_ID -D artifacts/
```

### Via AWS CLI (Local Deployment)

For immediate deployment without GitHub Actions:

```bash
cd fraud-detection-system/infrastructure

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Generate plan
terraform plan -out=tfplan

# Review plan
# Then apply
terraform apply tfplan

# Save outputs
terraform output -json > outputs.json
```

---

## Deploying Models

### Automatic ML Pipeline

```bash
# Trigger via workflow_dispatch
gh workflow run ml-pipeline.yml \
  --ref main \
  -f data_source=generate \
  -f deploy_model=true

# Monitor execution
gh run watch ML_PIPELINE_RUN_ID
```

### Manual Model Deployment

```bash
# After model is exported to ONNX and uploaded to S3

# Get model details
MODEL_VERSION=$(date +%Y%m%d_%H%M%S)
MODELS_BUCKET="your-models-bucket"

# Update KServe manifest with new model path
kubectl patch inferenceservice fraud-detector \
  -n kserve-inference \
  --type merge \
  -p '{"spec":{"predictor":{"model":{"modelFormat":{"name":"triton"},"storageUri":"s3://'"$MODELS_BUCKET"'/'"$MODEL_VERSION"'/"}}}}'

# Verify deployment
kubectl get inferenceservice fraud-detector -n kserve-inference

# Test inference
curl -X POST http://fraud-detector.kserve-inference.svc.cluster.local:8000/v1/models/fraud-detector:predict \
  -H "Content-Type: application/json" \
  -d '{"instances":[[150.50, 1234, 1, 2, 0, 14, 3, ...]]}'
```

---

## Monitoring & Troubleshooting

### View Workflow Executions

```bash
# List recent runs
gh run list --workflow terraform.yml --limit 10

# Get detailed status
gh run view RUN_ID

# View full logs
gh run view RUN_ID --log | less

# Follow in real-time
gh run watch RUN_ID
```

### Common Issues

#### OIDC Authentication Fails

**Error**: `InvalidParameterException: Invalid OIDC provider`

**Solution**:
```bash
# Verify OIDC provider exists
aws iam list-open-id-connect-providers

# Recreate if needed with correct thumbprint
curl -s https://token.actions.githubusercontent.com/.well-known/openid-configuration | jq
```

#### Terraform State Lock

**Error**: `Error acquiring the state lock`

**Solution**:
```bash
# View locks
aws dynamodb scan --table-name terraform-locks

# Force unlock
aws dynamodb delete-item \
  --table-name terraform-locks \
  --key '{"LockID":{"S":"fraud-detection-terraform-state/prod/terraform.tfstate"}}'
```

#### S3 Access Denied

**Error**: `Access Denied (403)`

**Solution**:
1. Verify S3 bucket policy includes GitHub Actions role
2. Check IAM role permissions include S3:*
3. Verify bucket encryption algorithm (should be AES256)

#### EKS Cluster Creation Fails

**Error**: `Service role is not authorized to perform`

**Solution**:
1. Check IAM role has EKS service permissions
2. Verify subnets exist and have internet access
3. Check security group rules for required ports

### Enable Debug Logging

```bash
# Set GitHub Actions debug environment variable
gh secret create ACTIONS_STEP_DEBUG --body true

# In workflow, logs will now include extended debugging information
```

### Validate Configuration Locally

```bash
# Lint GitHub Actions workflows
pip install yamllint
yamllint .github/workflows/

# Test Terraform locally
cd infrastructure
terraform plan -no-color > plan.txt
# Review plan.txt for errors
```

---

## Security Best Practices

### 1. Credential Management

✅ **DO**:
- Use OIDC federation for authentication
- Store secrets in GitHub Secrets, not code
- Rotate credentials regularly
- Use least privilege IAM policies

❌ **DON'T**:
- Commit AWS credentials to repository
- Use long-lived access keys
- Grant overly broad permissions
- Share secrets across multiple repositories

### 2. Code Review Process

```
Feature Branch → Pull Request → Code Review → Approval → Merge → Deploy
```

**Review Checklist**:
- [ ] Terraform changes validated
- [ ] Security scan passed
- [ ] Cost estimation reviewed
- [ ] No hardcoded credentials
- [ ] Comments explain significant changes

### 3. Environment Isolation

```
Development → Staging → Production
  (manual)   (manual)   (auto plan)
                        (manual apply)
```

Use branch protection and environment approval gates:

```yaml
environments:
  production:
    required_reviewers: 2
    deployment_branches: [main]
    auto_rollback: true
```

### 4. Audit Logging

```bash
# Enable CloudTrail for API audit
aws cloudtrail start-logging --trail-name fraud-detection-trail

# Enable CloudWatch Logs for OIDC events
aws logs create-log-group --log-group-name /aws/github-actions/

# Review GitHub Actions audit log
gh api repos/{owner}/{repo}/audit-log
```

### 5. Secret Rotation

```bash
# Update GitHub Actions role every 90 days
./cicd/setup_github_oidc.sh --rotate

# Review and revoke unused permissions
aws iam list-role-policies --role-name github-actions-fraud-detection
```

---

## Next Steps

1. **Run AWS Setup**: `./cicd/setup_github_oidc.sh`
2. **Configure Secrets**: Add `AWS_ROLE_ARN` and `AWS_ACCOUNT_ID` to GitHub
3. **Generate Configuration**: Run `./infrastructure/setup.sh`
4. **Deploy Infrastructure**: Merge infrastructure PR to main
5. **Train Model**: Trigger ML pipeline workflow
6. **Deploy Model**: Update KServe service
7. **Monitor**: Set up CloudWatch and Grafana dashboards

---

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS OIDC Provider Setup](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments)
- [KServe Documentation](https://kserve.github.io/)
- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)

---

**Last Updated**: 2024
**Version**: 1.0.0
