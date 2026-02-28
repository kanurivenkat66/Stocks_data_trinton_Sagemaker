# KServe Module - Input Variables

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "kserve_role_arn" {
  description = "ARN of the KServe IRSA role"
  type        = string
}

variable "models_bucket" {
  description = "S3 bucket name for models"
  type        = string
}

variable "predictor_cpu_request" {
  description = "CPU request for predictor pod"
  type        = string
  default     = "500m"
}

variable "predictor_cpu_limit" {
  description = "CPU limit for predictor pod"
  type        = string
  default     = "2"
}

variable "predictor_memory_request" {
  description = "Memory request for predictor pod"
  type        = string
  default     = "1Gi"
}

variable "predictor_memory_limit" {
  description = "Memory limit for predictor pod"
  type        = string
  default     = "4Gi"
}

variable "predictor_gpu_limit" {
  description = "GPU limit for predictor pod"
  type        = number
  default     = 1
}

variable "hpa_min_replicas" {
  description = "Minimum replicas for HPA"
  type        = number
  default     = 3

  validation {
    condition     = var.hpa_min_replicas >= 1
    error_message = "Minimum replicas must be at least 1"
  }
}

variable "hpa_max_replicas" {
  description = "Maximum replicas for HPA"
  type        = number
  default     = 10

  validation {
    condition     = var.hpa_max_replicas >= 1
    error_message = "Max replicas must be at least 1"
  }
}

variable "hpa_target_cpu" {
  description = "Target CPU utilization percentage for HPA"
  type        = number
  default     = 80

  validation {
    condition     = var.hpa_target_cpu > 0 && var.hpa_target_cpu <= 100
    error_message = "Target CPU must be between 1 and 100"
  }
}

variable "hpa_target_memory" {
  description = "Target memory utilization percentage for HPA"
  type        = number
  default     = 80

  validation {
    condition     = var.hpa_target_memory > 0 && var.hpa_target_memory <= 100
    error_message = "Target memory must be between 1 and 100"
  }
}

variable "enable_monitoring" {
  description = "Enable Prometheus monitoring"
  type        = bool
  default     = true
}

variable "kserve_helm_release_id" {
  description = "Dependency on KServe Helm release"
  type        = any
  default     = null
}
