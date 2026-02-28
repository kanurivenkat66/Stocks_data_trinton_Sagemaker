# Karpenter Module - Input Variables

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "karpenter_role_arn" {
  description = "ARN of the Karpenter IRSA role"
  type        = string
}

variable "karpenter_node_role_name" {
  description = "Name of the Karpenter node IAM role"
  type        = string
}

variable "cpu_instance_types" {
  description = "CPU instance types for Karpenter"
  type        = list(string)
  default     = ["t3.large", "t3.xlarge", "t3.2xlarge"]
}

variable "cpu_pool_max_cpu" {
  description = "Maximum CPUs for CPU node pool"
  type        = string
  default     = "1000"
}

variable "cpu_pool_max_memory" {
  description = "Maximum memory for CPU node pool"
  type        = string
  default     = "1000Gi"
}

variable "enable_gpu_pool" {
  description = "Enable GPU node pool"
  type        = bool
  default     = true
}

variable "gpu_instance_types" {
  description = "GPU instance types for Karpenter"
  type        = list(string)
  default     = ["g4dn.xlarge", "g4dn.2xlarge"]
}

variable "gpu_pool_max_cpu" {
  description = "Maximum CPUs for GPU node pool"
  type        = string
  default     = "100"
}

variable "gpu_pool_max_memory" {
  description = "Maximum memory for GPU node pool"
  type        = string
  default     = "500Gi"
}

variable "node_ttl_seconds" {
  description = "Seconds before removing idle nodes"
  type        = number
  default     = 2592000  # 30 days

  validation {
    condition     = var.node_ttl_seconds > 0
    error_message = "Node TTL must be positive"
  }
}

variable "node_root_volume_size" {
  description = "Root volume size in GB for nodes"
  type        = number
  default     = 100

  validation {
    condition     = var.node_root_volume_size >= 20
    error_message = "Root volume must be at least 20 GB"
  }
}

variable "karpenter_helm_release_id" {
  description = "Dependency on Karpenter Helm release"
  type        = any
  default     = null
}
