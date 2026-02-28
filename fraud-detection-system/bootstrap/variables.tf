variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d{1}$", var.aws_region))
    error_message = "AWS region must be valid (e.g., us-west-2)"
  }
}

variable "github_org" {
  description = "GitHub organization name"
  type        = string

  validation {
    condition     = length(var.github_org) > 0
    error_message = "GitHub organization cannot be empty"
  }
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string

  validation {
    condition     = length(var.github_repo) > 0
    error_message = "GitHub repository cannot be empty"
  }
}

variable "github_allowed_branches" {
  description = "GitHub branches allowed to use OIDC (empty = all branches)"
  type        = list(string)
  default     = ["main", "develop"]
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "fraud-detection"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod"
  }
}

variable "enable_state_locking" {
  description = "Enable DynamoDB state locking"
  type        = bool
  default     = true
}

variable "state_bucket_encryption" {
  description = "Enable S3 state bucket encryption"
  type        = bool
  default     = true
}

variable "state_bucket_versioning" {
  description = "Enable S3 state bucket versioning"
  type        = bool
  default     = true
}

variable "state_bucket_lifecycle_days" {
  description = "Days before old state versions are deleted"
  type        = number
  default     = 90

  validation {
    condition     = var.state_bucket_lifecycle_days > 0
    error_message = "Lifecycle days must be positive"
  }
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Purpose   = "CI/CD Bootstrap"
  }
}
