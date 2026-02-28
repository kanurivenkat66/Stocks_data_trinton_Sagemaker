locals {
  # GitHub OIDC token provider endpoint
  github_oidc_provider_url = "https://token.actions.githubusercontent.com"
  
  # GitHub's certificate thumbprint (public, static value)
  # This is GitHub's official OIDC provider thumbprint
  # Reference: https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect
  github_oidc_thumbprint = "6d4b1018202e31b925e63d821425301b7d8e4dd2"
  
  # IAM role configuration
  role_name = "${var.project_name}-github-actions"
  
  # S3 bucket configuration
  state_bucket_name = "${var.project_name}-terraform-state-${data.aws_caller_identity.current.account_id}"
  
  # DynamoDB table configuration
  locked_table_name = "terraform-locks"
  
  # Subject patterns for GitHub OIDC trust policy
  # This controls which GitHub Actions workflows can assume the role
  github_subjects = concat(
    # Allow from specific branches
    [for branch in var.github_allowed_branches : "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${branch}"],
    # Also allow pull requests
    ["repo:${var.github_org}/${var.github_repo}:pull_request"]
  )
  
  # Common tags
  common_tags = merge(
    var.tags,
    {
      Project     = var.project_name
      Environment = var.environment
      Module      = "bootstrap"
      CreatedAt   = timestamp()
    }
  )
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}
data "aws_region" "current" {
  provider = aws
}
