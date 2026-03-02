# SageMaker Module - Input Variables

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enabled" {
  description = "Master switch - enable all SageMaker resources"
  type        = bool
  default     = true
}

variable "execution_role_arn" {
  description = "IAM role ARN for SageMaker execution"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "VPC ID for SageMaker Studio network isolation"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for SageMaker Studio and Feature Store"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "Security group IDs for SageMaker Studio VPC access"
  type        = list(string)
}

variable "feature_store_s3_bucket" {
  description = "S3 bucket name for Feature Store offline storage"
  type        = string
}

variable "enable_studio" {
  description = "Enable SageMaker Studio domain"
  type        = bool
  default     = true
}

variable "studio_user_profiles" {
  description = "List of Studio user profile names to create"
  type        = list(string)
  default     = ["data-scientist", "mlops-engineer"]
}

variable "enable_feature_store" {
  description = "Enable SageMaker Feature Store feature groups"
  type        = bool
  default     = true
}

variable "enable_model_registry" {
  description = "Enable SageMaker Model Package Group for model versioning"
  type        = bool
  default     = true
}
