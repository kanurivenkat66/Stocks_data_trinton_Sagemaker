#!/bin/bash

###############################################################################
# GitHub Actions CLI Quick Reference
# Useful commands for managing CI/CD pipelines
###############################################################################

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}GitHub Actions CLI Quick Reference${NC}\n"

# Installation
echo -e "${GREEN}Installation:${NC}"
echo "  Windows:   choco install gh"
echo "  macOS:     brew install gh"
echo "  Linux:     apt/yum install gh"
echo "  GitHub CLI: https://cli.github.com"
echo ""

# Authentication
echo -e "${GREEN}Authentication:${NC}"
echo "  gh auth login                   # Login to GitHub"
echo "  gh auth logout                  # Logout"
echo "  gh auth status                  # Check authentication"
echo ""

# Workflows
echo -e "${GREEN}Workflow Management:${NC}"
echo "  gh workflow list                # List all workflows"
echo "  gh workflow list -L 50          # List 50 workflows"
echo "  gh workflow view WORKFLOW_ID    # View workflow details"
echo "  gh workflow disable WORKFLOW    # Disable workflow"
echo "  gh workflow enable WORKFLOW     # Enable workflow"
echo ""

# Running Workflows
echo -e "${GREEN}Trigger Workflows:${NC}"
echo "  gh workflow run terraform.yml --ref main"
echo "  gh workflow run terraform.yml -f action=plan"
echo "  gh workflow run ml-pipeline.yml -f data_source=generate -f deploy_model=true"
echo ""

# Runs
echo -e "${GREEN}View Workflow Runs:${NC}"
echo "  gh run list                     # List recent runs"
echo "  gh run list --workflow terraform.yml  # Filter by workflow"
echo "  gh run list -L 20               # Show 20 runs"
echo "  gh run list --status completed  # Filter by status (completed, failed, pending, etc)"
echo ""

# Run Details
echo -e "${GREEN}View Run Details:${NC}"
echo "  gh run view RUN_ID              # View run summary"
echo "  gh run view RUN_ID --log        # View full logs"
echo "  gh run view RUN_ID --log | grep 'ERROR'  # Find errors"
echo "  gh run watch RUN_ID             # Follow run in real-time"
echo ""

# Artifacts
echo -e "${GREEN}Download Artifacts:${NC}"
echo "  gh run download RUN_ID -D artifacts/"
echo "  gh run download RUN_ID -n artifact-name  # Specific artifact"
echo "  ls -la artifacts/               # View downloaded files"
echo ""

# Delete Runs
echo -e "${GREEN}Delete Runs:${NC}"
echo "  gh run delete RUN_ID"
echo "  gh run delete RUN_ID --confirm  # Skip confirmation"
echo ""

# Secrets
echo -e "${GREEN}Manage Secrets:${NC}"
echo "  gh secret list                  # List secrets"
echo "  gh secret create SECRET_NAME    # Create secret (interactive)"
echo "  gh secret set SECRET_NAME < secret.txt  # Create with file"
echo "  gh secret remove SECRET_NAME    # Delete secret"
echo ""

# Variables
echo -e "${GREEN}Manage Variables:${NC}"
echo "  gh variable list                # List variables"
echo "  gh variable create VAR_NAME     # Create variable"
echo "  gh variable set VAR_NAME --body VALUE"
echo "  gh variable delete VAR_NAME     # Delete variable"
echo ""

# Examples
echo -e "${GREEN}Common Workflows:${NC}"
echo ""
echo "  1. Deploy Infrastructure"
echo "     gh workflow run terraform.yml --ref main -f action=plan"
echo "     # Review in GitHub UI"
echo "     gh workflow run terraform.yml --ref main -f action=apply"
echo ""
echo "  2. Train and Deploy Model"
echo "     gh workflow run ml-pipeline.yml -f data_source=generate -f deploy_model=true"
echo "     gh run watch <RUN_ID>"
echo ""
echo "  3. Monitor Deployment"
echo "     gh run list --workflow terraform.yml"
echo "     gh run view <RUN_ID>"
echo ""
echo "  4. Download Artifacts"
echo "     gh run download <RUN_ID> -D artifacts/"
echo "     cat artifacts/deployment-summary.md"
echo ""
echo "  5. Enable Debug Logging"
echo "     gh secret create ACTIONS_STEP_DEBUG --body true"
echo "     # Re-run workflow to see extended logs"
echo ""

# Useful Combined Commands
echo -e "${GREEN}Useful Combined Commands:${NC}"
echo ""
echo "  # Get latest terraform run"
echo "  LATEST_RUN=\$(gh run list --workflow terraform.yml -L 1 --json name,databaseId -q .[].databaseId)"
echo "  gh run view \$LATEST_RUN"
echo ""
echo "  # Download latest terraform artifacts"
echo "  LATEST_RUN=\$(gh run list --workflow terraform.yml -L 1 --json databaseId -q .[].databaseId)"
echo "  gh run download \$LATEST_RUN -D artifacts/"
echo ""
echo "  # Re-run failed workflow"
echo "  gh run rerun <RUN_ID>"
echo "  gh run rerun <RUN_ID> --failed  # Re-run only failed jobs"
echo ""

# Tips
echo -e "${GREEN}Tips & Tricks:${NC}"
echo "  • Use 'gh run watch' for real-time monitoring"
echo "  • Check logs with: gh run view RUN_ID --log | grep -i error"
echo "  • Download all artifacts: gh run download RUN_ID -D artifacts/"
echo "  • Create shell alias: alias gha='gh run list --workflow'"
echo "  • Export results: gh run list --json status,conclusion,name"
echo ""

# Troubleshooting
echo -e "${GREEN}Troubleshooting:${NC}"
echo "  gh run logs RUN_ID              # View logs (if available)"
echo "  gh run view RUN_ID --verbose    # Verbose output"
echo "  gh auth refresh                 # Refresh authentication"
echo "  gh issue list                   # Related issues"
echo "  gh pr list                      # Pull requests"
echo ""

# Links
echo -e "${GREEN}Documentation:${NC}"
echo "  GitHub Actions: https://cli.github.com/manual/gh_run"
echo "  Workflows: https://github.com/fraud-detection-system/actions"
echo "  Status: https://www.githubstatus.com"
echo ""
