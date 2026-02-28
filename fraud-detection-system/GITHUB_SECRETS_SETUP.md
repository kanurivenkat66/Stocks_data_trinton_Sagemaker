#!/bin/bash

# Configure GitHub Secrets for CI/CD
# This script guides you through adding AWS credentials to GitHub

cat << 'EOF'

╔═══════════════════════════════════════════════════════════════════════╗
║                  GITHUB SECRETS CONFIGURATION                        ║
║                                                                       ║
║  Step 1: Two Ways to Configure GitHub Secrets                       ║
╚═══════════════════════════════════════════════════════════════════════╝

Option A: Web UI (Easiest)
═══════════════════════════════════════════════════════════════════════

1. Go to GitHub: https://github.com/kanurivenkat66/Stocks_data_trinton_Sagemaker
2. Click Settings → Secrets and variables → Actions
3. Click "New repository secret" button
4. Add these 3 secrets:

   SECRET #1: AWS_ROLE_ARN
   ├─ Name: AWS_ROLE_ARN
   └─ Value: arn:aws:iam::889526028446:role/github-actions-fraud-detection

   SECRET #2: AWS_REGION
   ├─ Name: AWS_REGION
   └─ Value: us-west-2

   SECRET #3: SLACK_WEBHOOK_URL (Optional)
   ├─ Name: SLACK_WEBHOOK_URL
   └─ Value: https://hooks.slack.com/services/YOUR/WEBHOOK/URL
   └─ (Skip if you don't have Slack integration)

5. Click "Add secret" after each value

EOF

echo ""
echo "Option B: GitHub CLI (Automated)"
echo "═══════════════════════════════════════════════════════════════════════"
echo ""
echo "If you have GitHub CLI installed (gh), run these commands:"
echo ""
echo "gh secret set AWS_ROLE_ARN --body 'arn:aws:iam::889526028446:role/github-actions-fraud-detection'"
echo "gh secret set AWS_REGION --body 'us-west-2'"
echo ""
echo "To set Slack webhook (optional):"
echo "gh secret set SLACK_WEBHOOK_URL --body 'YOUR_WEBHOOK_URL'"
echo ""

cat << 'EOF'

═══════════════════════════════════════════════════════════════════════

Step 2: Verify Secrets Were Added
═══════════════════════════════════════════════════════════════════════

1. Go to: https://github.com/kanurivenkat66/Stocks_data_trinton_Sagemaker/settings/secrets/actions
2. Verify you see 2-3 secrets listed:
   ✓ AWS_ROLE_ARN
   ✓ AWS_REGION
   ✓ SLACK_WEBHOOK_URL (optional)

═══════════════════════════════════════════════════════════════════════

Step 3: Push Code to GitHub
═══════════════════════════════════════════════════════════════════════

From your local workspace, run:

   cd /workspaces/Stocks_data_trinton_Sagemaker
   git add .
   git commit -m "feat: Add production-grade modular Terraform infrastructure"
   git push origin main

This will trigger:
   1. terraform-plan workflow (validates infrastructure)
   2. terraform-apply workflow (deploys to AWS)

═══════════════════════════════════════════════════════════════════════

Step 4: Monitor GitHub Actions
═══════════════════════════════════════════════════════════════════════

1. Go to: https://github.com/kanurivenkat66/Stocks_data_trinton_Sagemaker/actions
2. Watch workflows as they execute
3. Expected time: 20-30 minutes for full infrastructure deployment

Timeline:
   ├─ terraform-plan:  ~5 min (validates Terraform)
   ├─ terraform-apply: ~25 min (creates all AWS resources)
   └─ Completion: Check for green checkmarks ✓

═══════════════════════════════════════════════════════════════════════

Step 5: After Deployment - Connect to Cluster
═══════════════════════════════════════════════════════════════════════

Once terraform-apply completes, run this to connect to your EKS cluster:

   aws eks update-kubeconfig --region us-west-2 --name fraud-detection-cluster

Verify cluster access:

   kubectl get nodes
   kubectl get pods -A

You should see:
   ✓ 3+ CPU nodes (t3.large/xlarge)
   ✓ 1 GPU node (g4dn.xlarge) - if enabled
   ✓ kserve-inference namespace with pods
   ✓ karpenter namespace with pods

═══════════════════════════════════════════════════════════════════════

IMPORTANT: GitHub Secrets Security

✅ Secrets are encrypted at rest
✅ Secrets are masked in logs
✅ Secrets only accessible to workflows in this repo
✅ No need to store long-lived AWS credentials

All authentication happens via OIDC:
   GitHub → AWS OIDC Provider → Temporary credentials (1 hour)
   No credentials stored in GitHub!

═══════════════════════════════════════════════════════════════════════

Troubleshooting
═══════════════════════════════════════════════════════════════════════

If terraform-apply fails:
   1. Check GitHub Actions log for error
   2. Common issues:
      - AWS service quota exceeded (request limit increase)
      - VPC/subnet CIDR conflicts
      - Insufficient IAM permissions (shouldn't happen with bootstrap)

If pods won't start:
   1. Check CloudWatch logs: /aws/eks/fraud-detection-cluster
   2. Describe pods: kubectl describe pod POD_NAME -n NAMESPACE
   3. Check node capacity: kubectl describe nodes

═══════════════════════════════════════════════════════════════════════

Next: Data Pipeline & Model Training

After infrastructure is deployed, you can:

1. Generate training data:
   gh workflow run data-pipeline.yml -f num_samples=100000

2. Train model:
   gh workflow run model-training.yml -f model_type=xgboost

3. Deploy to KServe:
   gh workflow run model-deploy.yml -f environment=staging

═══════════════════════════════════════════════════════════════════════

Questions?

📖 Read: fraud-detection-system/cicd/EXECUTION_PLAN.md
📖 Read: fraud-detection-system/README.md
💬 Check: GitHub Issues

Good luck! 🚀

EOF
