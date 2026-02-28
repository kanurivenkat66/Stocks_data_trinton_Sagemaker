# Root Module - Local Values
# Common values used across modules

locals {
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      CreatedAt   = timestamp()
      Module      = "root"
    }
  )
}
