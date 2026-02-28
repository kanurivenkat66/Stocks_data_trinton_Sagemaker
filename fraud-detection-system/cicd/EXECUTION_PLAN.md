# 🎯 CI/CD Deployment Execution Plan

## Current Status

✅ **Complete**: GitHub Actions workflows created
✅ **Complete**: Terraform infrastructure files ready
✅ **Todo**: AWS OIDC setup
✅ **Todo**: GitHub Secrets configuration

---

## 📋 STEP-BY-STEP EXECUTION

### Phase 1: Setup AWS OIDC (15 minutes)

This creates secure, temporary AWS credentials for GitHub Actions (no long-lived secrets).

**Run this command:**

```bash
cd fraud-detection-system/cicd
chmod +x setup_github_oidc.sh
./setup_github_oidc.sh
```

**What it does:**
1. ✅ Creates OIDC provider in AWS
2. ✅ Creates IAM role for GitHub Actions
3. ✅ Attaches IAM policy
4. ✅ Creates S3 bucket for Terraform state
5. ✅ Creates DynamoDB table for locks
6. ✅ Outputs secrets to configure

**Output you'll get:**
```
AWS_ROLE_TO_ASSUME = arn:aws:iam::123456789:role/fraud-detection-github-actions
AWS_REGION = us-west-2
```

---

### Phase 2: Configure GitHub Secrets (5 minutes)

Store the outputs from Phase 1 in GitHub.

**Steps:**

1. Go to GitHub repository
2. **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**

**Add these secrets:**

| Secret | Value |
|--------|-------|
| `AWS_ROLE_TO_ASSUME` | From Phase 1 output (ARN) |
| `AWS_REGION` | `us-west-2` |
| `SLACK_WEBHOOK_URL` | (Optional) Your Slack webhook URL |

---

### Phase 3: Verify Setup (5 minutes)

Test that everything works.

**Method 1: Push to GitHub**

```bash
# Commit and push
git add .github/workflows/
git commit -m "feat: Add GitHub Actions CI/CD pipeline"
git push origin main

# GitHub Actions starts automatically
# Go to repo → Actions tab → see workflow run
```

**Method 2: Manual Workflow Trigger**

```bash
# Using GitHub CLI (if installed)
gh workflow run terraform-plan.yml --ref main

# Or via GitHub UI:
# 1. Go to Actions tab
# 2. Select "Terraform Plan"
# 3. Click "Run workflow"
```

---

## 🔄 Complete Workflow

```
┌─ Development ──────────────────────────┐
│                                        │
│ 1. Make infrastructure changes         │
│    Edit: infrastructure/*.tf           │
│                                        │
│ 2. Commit and push                     │
│    git push origin feature/branch      │
│                                        │
│ 3. Create Pull Request                 │
│    GitHub PR created                   │
└────────────┬─────────────────────────────┘
             │
             ↓
┌─ Terraform Plan (PR) ──────────────────┐
│                                        │
│ ✅ terraform fmt -check                │
│ ✅ terraform validate                  │
│ ✅ terraform plan                      │
│ ✅ Comment on PR with summary          │
│                                        │
│ Review plan in PR comment              │
└────────────┬─────────────────────────────┘
             │
             ↓
┌─ Code Review ──────────────────────────┐
│                                        │
│ 1. Review changes                      │
│ 2. Review terraform plan               │
│ 3. Approve PR                          │
│ 4. Merge to main                       │
└────────────┬─────────────────────────────┘
             │
             ↓
┌─ Terraform Apply (Main) ───────────────┐
│                                        │
│ ✅ terraform init                      │
│ ✅ terraform validate                 │
│ ✅ terraform plan → tfplan             │
│ ✅ terraform apply tfplan              │
│ ✅ Get outputs                        │
│ ✅ Slack notification                  │
│                                        │
│ Infrastructure deployed!               │
└────────────┬─────────────────────────────┘
             │
             ↓
┌─ Optional: Trigger Data/ML Workflows ──┐
│                                        │
│ gh workflow run data-pipeline.yml      │
│ gh workflow run model-training.yml     │
│ gh workflow run model-deploy.yml       │
│                                        │
│ Models trained & deployed              │
└────────────────────────────────────────┘
```

---

## 📊 Workflow Triggers

### Automatic Triggers

| Workflow | Trigger | Schedule |
|----------|---------|----------|
| **Terraform Plan** | PR on `infrastructure/*` | On PR |
| **Terraform Apply** | Push to `main` on `infrastructure/*` | On merge |
| **Data Pipeline** | Schedule + Manual | 2 AM UTC daily |
| **Model Training** | Schedule + Manual | 4 AM UTC weekly |
| **Model Deploy** | Manual only | On demand |

### Manual Triggers (GitHub CLI)

```bash
# Trigger data pipeline
gh workflow run data-pipeline.yml \
  --ref main \
  -f num_samples=100000

# Trigger model training
gh workflow run model-training.yml \
  --ref main \
  -f model_type=xgboost \
  -f max_depth=8

# Trigger model deployment
gh workflow run model-deploy.yml \
  --ref main \
  -f model_version=latest \
  -f environment=staging
```

---

## ✅ What Workflows Do

### 1. Terraform Plan Workflow

**File**: `.github/workflows/terraform-plan.yml`

```yaml
Trigger: Pull request to infrastructure/
├─ Format check (terraform fmt)
├─ Validation (terraform validate)
├─ Plan generation (terraform plan)
├─ TFLint analysis
└─ PR comment with summary
```

**Example PR Comment Output:**
```
## Terraform Plan

Terraform will perform the following actions:

+ aws_eks_cluster.fraud_detection
  - name = "fraud-detection-cluster"
  - version = "1.27"

...

✅ Validation successful
✅ Plan generated
```

---

### 2. Terraform Apply Workflow

**File**: `.github/workflows/terraform-apply.yml`

```yaml
Trigger: Push to main (infrastructure/)
├─ Initialize Terraform
├─ Validate configuration
├─ Create plan
├─ Apply infrastructure
├─ Retrieve outputs
│  ├─ eks_cluster_name
│  ├─ data_bucket_name
│  └─ models_bucket_name
└─ Slack notification
```

---

### 3. Data Pipeline Workflow

**File**: `.github/workflows/data-pipeline.yml`

```yaml
Trigger: Schedule (2 AM UTC) or Manual
├─ Generate synthetic transaction data
├─ Preprocess & engineer features
├─ Validate data quality
├─ Split train/val/test
└─ Upload to S3
```

**Output**:
- `s3://fraud-detection-data-*/training-data/train.csv`
- `s3://fraud-detection-data-*/training-data/validation.csv`
- `s3://fraud-detection-data-*/training-data/test.csv`

---

### 4. Model Training Workflow

**File**: `.github/workflows/model-training.yml`

```yaml
Trigger: Schedule (Sunday 4 AM UTC) or Manual
├─ Check training data exists
├─ Train XGBoost/LightGBM model
├─ Evaluate performance
├─ Export to ONNX format
├─ Create model metadata
└─ Upload to S3 with versioning
```

**Output**:
- `s3://fraud-detection-models-*/fraud-detector/TIMESTAMP/model.onnx`
- `s3://fraud-detection-models-*/fraud-detector/latest/model.onnx`
- `s3://fraud-detection-models-*/fraud-detector/TIMESTAMP/metadata.json`

---

### 5. Model Deploy Workflow

**File**: `.github/workflows/model-deploy.yml`

```yaml
Trigger: Manual only
├─ Get latest model version
├─ Create KServe manifest
├─ Deploy to EKS
├─ Wait for pods ready
├─ Test inference
└─ Output service endpoint
```

---

## 🔐 Security Architecture

### OIDC Flow

```
GitHub Action
    │
    ├─ Generates JWT token
    │
    ↓
AWS STS (Secure Token Service)
    │
    ├─ Validates JWT signature
    ├─ Checks OIDC provider
    ├─ Verifies subject (repo/branch)
    │
    ↓
AWS IAM
    │
    ├─ Checks role trust policy
    ├─ Verifies subject matches
    │
    ↓
Assume Role
    │
    ├─ Returns temporary credentials
    │   (AccessKeyId, SecretAccessKey, SessionToken)
    ├─ TTL: 1 hour
    │
    ↓
Workflow Uses Credentials
    │
    ├─ Runs AWS CLI/Terraform/etc
    │
    ↓
Credentials Expire
    │
    └─ Auto cleanup, no manual revocation
```

**Benefits:**
✅ No long-lived credentials stored
✅ No AWS access keys in GitHub
✅ Automatic credential rotation
✅ Audit trail in CloudTrail
✅ Can restrict to specific repo/branch

---

## 🚀 Deployment Scenarios

### Scenario 1: Deploy Only Infrastructure

1. Make changes to `infrastructure/*.tf`
2. Create PR
3. Review terraform plan
4. Merge PR
5. Terraform Apply runs automatically ✅

**Time**: ~30 minutes

---

### Scenario 2: Full End-to-End (Infra + Data + Model)

1. Merge infrastructure changes→ Terraform applies ✅
2. Trigger data pipeline: `gh workflow run data-pipeline.yml`
3. Trigger training: `gh workflow run model-training.yml` (30 min)
4. Trigger deployment: `gh workflow run model-deploy.yml` ✅

**Time**: ~1.5 hours

---

### Scenario 3: Re-train & Deploy Latest Model

1. Trigger training: `gh workflow run model-training.yml -f learning_rate=0.05`
2. Wait for training (30 min)
3. Trigger deployment: `gh workflow run model-deploy.yml -f environment=staging`

**Time**: ~35 minutes (faster, infrastructure already exists)

---

## 📊 Monitoring Workflows

### GitHub Actions UI

1. Go to **Actions** tab
2. Select workflow name
3. See run history with status
4. Click run to see details/logs

### GitHub CLI Commands

```bash
# List all runs
gh run list

# Show specific workflow runs
gh run list --workflow terraform-apply.yml

# View run details
gh run view RUN_ID

# Download artifacts
gh run download RUN_ID -n ARTIFACT_NAME

# View logs
gh run view RUN_ID --log
```

### Slack Notifications

When configured, receive:
- ✅ Infrastructure deployment success
- ❌ Infrastructure deployment failure  
- ✅ Model training complete
- ✅ Model deployment successful

---

## 🔧 Troubleshooting

### OIDC Not Working

```bash
# Check OIDC provider exists
aws iam list-open-id-connect-providers

# Check role trust policy
aws iam get-role --role-name fraud-detection-github-actions

# Verify role has policy attached
aws iam list-role-policies --role-name fraud-detection-github-actions
```

### Workflow Fails with "InvalidIdentityToken"

**Cause**: OIDC provider not found or trust policy mismatch

**Solution**:
```bash
# Re-run setup script
cd cicd && ./setup_github_oidc.sh

# Or manually create OIDC provider:
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list THUMBPRINT
```

### Terraform State Lock

If plan is stuck with lock:

```bash
cd infrastructure
terraform force-unlock LOCK_ID
```

### Model Deployment Fails

**Check pod status**:
```bash
# Get cluster credentials
aws eks update-kubeconfig --region us-west-2 --name fraud-detection-cluster

# Check pods
kubectl get pods -n kserve-inference

# View logs
kubectl logs POD_NAME -n kserve-inference
```

---

## 🎯 Next Steps

### Immediate (Now)

1. **Run OIDC setup**:
   ```bash
   cd fraud-detection-system/cicd
   chmod +x setup_github_oidc.sh
   ./setup_github_oidc.sh
   ```

2. **Configure GitHub Secrets**:
   - Go to GitHub repo → Settings → Secrets
   - Add `AWS_ROLE_TO_ASSUME` and `AWS_REGION`

3. **Push to GitHub**:
   ```bash
   git add .github/
   git commit -m "feat: Add CI/CD pipelines"
   git push origin main
   ```

### After Setup

1. **Test workflows**:
   - Create test PR to `infrastructure/`
   - See terraform plan in PR comment
   - Merge and watch apply

2. **Configure optional features**:
   - Add Slack webhook for notifications
   - Adjust schedules in workflows
   - Configure auto-approval (not recommended for prod)

3. **Run full pipeline**:
   - Deploy infrastructure
   - Run data pipeline
   - Train model
   - Deploy to production

---

## 📚 Additional Resources

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [OIDC Documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [Terraform GitHub Actions](https://github.com/hashicorp/setup-terraform)
- [AWS GitHub Actions](https://github.com/aws-actions/configure-aws-credentials)

---

**Ready to setup CI/CD? Let's go! 🚀**
