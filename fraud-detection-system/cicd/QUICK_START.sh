#!/bin/bash

cat << 'EOF'

╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║                   ✅ COMPLETE CI/CD PIPELINE SETUP                          ║
║                                                                              ║
║              GitHub Actions + AWS OIDC + Terraform Automation               ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝


📦 WHAT HAS BEEN CREATED
════════════════════════════════════════════════════════════════════════════════

✅ GitHub Actions Workflows (.github/workflows/)
   ├── terraform-plan.yml         → Validates Terraform on PR
   ├── terraform-apply.yml        → Deploys infrastructure on merge
   ├── data-pipeline.yml          → Generates training data (daily)
   ├── model-training.yml         → Trains model (weekly)
   └── model-deploy.yml           → Deploys to KServe (manual)

✅ AWS Setup Scripts (cicd/)
   ├── setup_github_oidc.sh       → Creates OIDC trust for GitHub
   ├── CI_CD_SETUP_GUIDE.md       → Detailed setup instructions
   ├── EXECUTION_PLAN.md          → Step-by-step execution guide
   ├── GITHUB_CLI_REFERENCE.sh    → Useful GitHub CLI commands
   ├── github-actions-policy.json → IAM policy for GitHub Actions
   └── github-oidc-trust-policy.json → OIDC trust policy


🎯 NEXT STEPS (IN ORDER)
════════════════════════════════════════════════════════════════════════════════

STEP 1: Setup AWS OIDC (15 minutes)
─────────────────────────────────
This creates secure GitHub-to-AWS authentication (no long-lived credentials!)

Run:
  cd fraud-detection-system/cicd
  chmod +x setup_github_oidc.sh
  ./setup_github_oidc.sh

Output:
  - AWS_ROLE_TO_ASSUME: arn:aws:iam::123456789:role/fraud-detection-github-actions
  - AWS_REGION: us-west-2
  
Save these values!


STEP 2: Configure GitHub Secrets (5 minutes)
─────────────────────────────────────────────
Store OIDC outputs in GitHub for workflows to use

Go to:
  GitHub repo → Settings → Secrets and variables → Actions

Create these secrets:

  Name: AWS_ROLE_TO_ASSUME
  Value: arn:aws:iam::123456789:role/fraud-detection-github-actions
  
  Name: AWS_REGION
  Value: us-west-2

Optional:
  Name: SLACK_WEBHOOK_URL
  Value: https://hooks.slack.com/services/YOUR/WEBHOOK


STEP 3: Push to GitHub (1 minute)
──────────────────────────────────
Commit and push workflows to GitHub

Run:
  git add .github/workflows/
  git commit -m "feat: Add CI/CD pipeline with GitHub Actions"
  git push origin main


STEP 4: Verify Setup (2 minutes)
────────────────────────────────
Test that workflows trigger correctly

Go to:
  GitHub repo → Actions tab
  
You should see workflow runs starting


STEP 5: Deploy Infrastructure (30 minutes)
───────────────────────────────────────────
Let CI/CD pipeline deploy your infrastructure

Method 1 - Create PR (recommended for safety):
  1. Create new branch: git checkout -b feature/deploy-infra
  2. Edit infrastructure/terraform.tfvars if needed
  3. Commit: git commit -am "config: Update infrastructure settings"
  4. Push: git push origin feature/deploy-infra
  5. Create PR on GitHub
  6. Review terraform plan in PR comment
  7. Merge PR
  8. Watch terraform-apply workflow run

Method 2 - Push directly to main:
  1. Edit infrastructure/terraform.tfvars
  2. git add infrastructure/
  3. git commit -m "infra: Deploy fraud detection cluster"
  4. git push origin main
  5. terraform-apply workflow runs automatically


STEP 6: Trigger Data Pipeline (15 minutes)
───────────────────────────────────────────
Generate synthetic transaction data

Using GitHub CLI:
  gh workflow run data-pipeline.yml --ref main -f num_samples=100000

Or manually via UI:
  1. Go to Actions tab
  2. Select "Data Pipeline"
  3. Click "Run workflow"
  4. Click "Run"


STEP 7: Train Model (30-60 minutes)
────────────────────────────────────
Train XGBoost model on the generated data

Using GitHub CLI:
  gh workflow run model-training.yml --ref main \
    -f model_type=xgboost \
    -f max_depth=8 \
    -f learning_rate=0.1

Or via GitHub UI:
  1. Go to Actions → "Model Training & Export"
  2. "Run workflow" → Fill parameters → "Run"


STEP 8: Deploy Model (10 minutes)
──────────────────────────────────
Deploy trained model to KServe on EKS

Using GitHub CLI:
  gh workflow run model-deploy.yml --ref main \
    -f environment=staging

Or via GitHub UI:
  1. Go to Actions → "Deploy Model to KServe"
  2. "Run workflow" → Select environment → "Run"


⏱️ TIMELINE
════════════════════════════════════════════════════════════════════════════════

▪ STEP 1 (Setup OIDC):        ~15 minutes
▪ STEP 2 (GitHub Secrets):    ~5 minutes
▪ STEP 3 (Push to GitHub):    ~1 minute
▪ STEP 4 (Verify):            ~2 minutes
▪ STEP 5 (Infrastructure):    ~30 minutes
▪ STEP 6 (Data):              ~15 minutes
▪ STEP 7 (Training):          ~60 minutes
▪ STEP 8 (Deploy):            ~10 minutes

═════════════════════════════════════════════════════════════════════════
TOTAL: ~2.5 hours for complete end-to-end deployment


📊 WHAT HAPPENS AUTOMATICALLY
════════════════════════════════════════════════════════════════════════════════

Infrastructure Changes (Push to infrastructure/):
  ├─ PR created: terraform plan runs, comment added to PR
  ├─ PR merged to main: terraform apply runs automatically
  └─ Slack notification sent with status

Data Pipeline (Manual or Daily 2 AM UTC):
  ├─ Generates 100,000 synthetic transactions
  ├─ Preprocesses and validates
  ├─ Splits into train/val/test
  └─ Uploads to S3

Model Training (Manual or Weekly Sunday 4 AM UTC):
  ├─ Checks training data exists
  ├─ Trains XGBoost/LightGBM
  ├─ Exports to ONNX format
  └─ Uploads versioned model to S3

Model Deployment (Manual only):
  ├─ Gets latest model version
  ├─ Creates KServe manifest
  ├─ Deploys to EKS
  ├─ Tests inference
  └─ Slack notification with endpoint


🔐 SECURITY
════════════════════════════════════════════════════════════════════════════════

✅ OIDC-Based Authentication
  ✓ No long-lived AWS access keys
  ✓ No credentials stored in GitHub
  ✓ Temporary credentials (valid ~1 hour)
  ✓ Auto-rotation, no manual management

✅ Terraform State Protection
  ✓ Encrypted at rest (S3 AES-256)
  ✓ Versioning enabled for recovery
  ✓ DynamoDB locking to prevent conflicts
  ✓ Public access blocked

✅ GitHub Secrets Encryption
  ✓ Encrypted at rest
  ✓ Masked in logs
  ✓ Never exposed in output

✅ IAM Least Privilege
  ✓ OIDC trust limited to specific repo
  ✓ Role policy scoped to necessary permissions
  ✓ Regional restriction (us-west-2)


🌳 FILE STRUCTURE
════════════════════════════════════════════════════════════════════════════════

fraud-detection-system/
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml      ← PR validation
│       ├── terraform-apply.yml     ← Infrastructure deployment
│       ├── data-pipeline.yml       ← Data generation
│       ├── model-training.yml      ← Model training
│       └── model-deploy.yml        ← KServe deployment
│
└── cicd/
    ├── setup_github_oidc.sh        ← Run this first!
    ├── CI_CD_SETUP_GUIDE.md        ← Detailed guide
    ├── EXECUTION_PLAN.md           ← Complete execution steps
    ├── GITHUB_CLI_REFERENCE.sh     ← CLI commands
    ├── github-actions-policy.json  ← IAM policy
    └── github-oidc-trust-policy.json ← OIDC policy


💡 USEFUL GITHUB CLI COMMANDS
════════════════════════════════════════════════════════════════════════════════

# List workflows
gh workflow list

# Trigger workflow with parameters
gh workflow run data-pipeline.yml --ref main -f num_samples=50000

# View recent runs
gh run list

# View specific run
gh run view RUN_ID

# View run logs
gh run view RUN_ID --log

# Download artifacts
gh run download RUN_ID -n artifacts-name

# Re-run failed workflow
gh run rerun RUN_ID


🎓 KEY CONCEPTS
════════════════════════════════════════════════════════════════════════════════

GitHub Actions:
  ✓ Workflow = Automated process triggered by GitHub events
  ✓ Job = Set of steps in a workflow
  ✓ Step = Single task (command, action, script)
  ✓ Artifact = Files created during workflow (retained after)

OIDC:
  ✓ OpenID Connect = Standard for federated authentication
  ✓ No credentials shared = Each run gets unique token
  ✓ Time-limited = Auto-expires after ~1 hour
  ✓ Auditability = Every action logged in CloudTrail

Terraform:
  ✓ IaC = Define AWS resources in code
  ✓ .tfvars = Variable values for your environment
  ✓ tfplan = Execution plan (what will change)
  ✓ State = Current infrastructure state (stored in S3)


📞 TROUBLESHOOTING QUICK REFERENCE
════════════════════════════════════════════════════════════════════════════════

Issue: "InvalidIdentityToken"
→ OIDC provider not created
→ Solution: Run setup_github_oidc.sh again

Issue: "Workflow not triggering"
→ GitHub Secrets not configured
→ Solution: Add AWS_ROLE_TO_ASSUME and AWS_REGION to secrets

Issue: "Terraform Apply Failed"
→ Check workflow logs in GitHub Actions
→ Solution: Fix error and retry

Issue: "Model Deployment Failed"
→ Check pod logs: kubectl logs -f POD_NAME -n kserve-inference
→ Solution: Debug and redeploy


✨ MONITORING YOUR SYSTEMS
════════════════════════════════════════════════════════════════════════════════

Workflow Status:
  GitHub Actions tab → See all workflow runs

Infrastructure Logs:
  AWS CloudWatch → /aws/eks/fraud-detection-cluster

Model Performance:
  Prometheus: kubectl port-forward -n prometheus svc/prometheus 9090:9090
  Grafana:    kubectl port-forward -n grafana svc/grafana 3000:3000

Slack Notifications:
  Check your Slack channel for:
  ✓ Infrastructure deploy status
  ✓ Model training completion
  ✓ Deployment success/failure


📈 SCALING THE SYSTEM
════════════════════════════════════════════════════════════════════════════════

More Models:
  → Create additional workflow files
  → Deploy multiple InferenceServices

More Frequent Training:
  → Edit `schedule` in model-training.yml
  → Change cron expression

Larger Infrastructure:
  → Edit terraform.tfvars (eks_max_size, instance_types)
  → Changes auto-deploy via pipeline

Different Regions:
  → Update AWS_REGION secret
  → Update infrastructure/provider.tf
  → Re-apply infrastructure


🎉 YOU'RE READY!
════════════════════════════════════════════════════════════════════════════════

Your CI/CD pipeline is fully configured. Now execute the steps:

1. Run: cd fraud-detection-system/cicd && ./setup_github_oidc.sh
2. Add secrets to GitHub
3. Push to GitHub
4. Watch the magic happen! ✨

For detailed instructions, see:
→ /fraud-detection-system/cicd/EXECUTION_PLAN.md
→ /fraud-detection-system/cicd/CI_CD_SETUP_GUIDE.md


════════════════════════════════════════════════════════════════════════════════

Questions? Check the documentation files in the cicd/ directory!

Happy CI/CD! 🚀

════════════════════════════════════════════════════════════════════════════════

EOF
