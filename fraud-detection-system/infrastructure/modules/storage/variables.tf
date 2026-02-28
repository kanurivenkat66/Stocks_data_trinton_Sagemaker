# Storage Module - Input Variables

variable "project_name" {
  description = "Project name for bucket naming"
  type        = string
}

variable "data_retention_days" {
  description = "Days to keep old versions of data files"
  type        = number
  default     = 90

  validation {
    condition     = var.data_retention_days > 0
    error_message = "Retention days must be positive"
  }
}

variable "model_retention_days" {
  description = "Days to keep old model versions"
  type        = number
  default     = 180

  validation {
    condition     = var.model_retention_days > 0
    error_message = "Retention days must be positive"
  }
}

variable "artifacts_retention_days" {
  description = "Days to keep old training artifacts"
  type        = number
  default     = 60

  validation {
    condition     = var.artifacts_retention_days > 0
    error_message = "Retention days must be positive"
  }
}

variable "log_retention_days" {
  description = "Days to keep logs"
  type        = number
  default     = 30

  validation {
    condition     = var.log_retention_days > 0
    error_message = "Retention days must be positive"
  }
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
