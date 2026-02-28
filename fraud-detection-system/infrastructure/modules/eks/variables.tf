# EKS Module - Input Variables

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"

  validation {
    condition     = can(regex("^\\d+\\.\\d+$", var.kubernetes_version))
    error_message = "Kubernetes version must be in format X.Y (e.g., 1.28)"
  }
}

variable "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  type        = string
}

variable "eks_node_role_arn" {
  description = "ARN of the EKS node IAM role"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the cluster"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnets are required for high availability"
  }
}

variable "eks_security_group_id" {
  description = "Security group ID for the EKS cluster"
  type        = string
}

variable "endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks with access to public endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enabled_cluster_log_types" {
  description = "List of control plane logging types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7

  validation {
    condition     = var.log_retention_days > 0
    error_message = "Log retention days must be positive"
  }
}

variable "cpu_instance_types" {
  description = "EC2 instance types for CPU node group"
  type        = list(string)
  default     = ["t3.large", "t3.xlarge"]
}

variable "cpu_desired_size" {
  description = "Desired number of CPU nodes"
  type        = number
  default     = 3

  validation {
    condition     = var.cpu_desired_size >= 1
    error_message = "Desired size must be at least 1"
  }
}

variable "cpu_min_size" {
  description = "Minimum number of CPU nodes"
  type        = number
  default     = 1

  validation {
    condition     = var.cpu_min_size >= 1
    error_message = "Minimum size must be at least 1"
  }
}

variable "cpu_max_size" {
  description = "Maximum number of CPU nodes"
  type        = number
  default     = 10

  validation {
    condition     = var.cpu_max_size >= 1
    error_message = "Max size must be at least 1"
  }
}

variable "enable_gpu" {
  description = "Enable GPU node group"
  type        = bool
  default     = true
}

variable "gpu_instance_types" {
  description = "EC2 instance types for GPU node group"
  type        = list(string)
  default     = ["g4dn.xlarge", "g4dn.2xlarge"]
}

variable "gpu_desired_size" {
  description = "Desired number of GPU nodes"
  type        = number
  default     = 1

  validation {
    condition     = var.gpu_desired_size >= 0
    error_message = "Desired size must be non-negative"
  }
}

variable "gpu_min_size" {
  description = "Minimum number of GPU nodes"
  type        = number
  default     = 0
}

variable "gpu_max_size" {
  description = "Maximum number of GPU nodes"
  type        = number
  default     = 5

  validation {
    condition     = var.gpu_max_size >= 1
    error_message = "Max size must be at least 1"
  }
}

variable "node_disk_size" {
  description = "EBS volume size for nodes in GB"
  type        = number
  default     = 100

  validation {
    condition     = var.node_disk_size >= 20
    error_message = "Disk size must be at least 20 GB"
  }
}

variable "use_spot_instances" {
  description = "Use Spot instances for cost savings"
  type        = bool
  default     = true
}

variable "vpc_cni_addon_version" {
  description = "Version of VPC CNI addon"
  type        = string
  default     = "v1.14.1-eksbuild.1"
}

variable "vpc_cni_role_arn" {
  description = "ARN of the role for VPC CNI (optional, if using custom)"
  type        = string
  default     = ""
}

variable "coredns_addon_version" {
  description = "Version of CoreDNS addon"
  type        = string
  default     = "v1.9.3-eksbuild.2"
}

variable "kube_proxy_addon_version" {
  description = "Version of kube-proxy addon"
  type        = string
  default     = "v1.28.1-eksbuild.1"
}

variable "ebs_csi_addon_version" {
  description = "Version of EBS CSI driver addon"
  type        = string
  default     = "v1.20.0-eksbuild.1"
}

variable "ebs_csi_role_arn" {
  description = "ARN of the role for EBS CSI (optional, if using custom)"
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Policy attachment dependencies (for explicit dependency management)
variable "iam_role_policy_attachment" {
  description = "Dependency on IAM role policy attachment"
  type        = any
  default     = null
}

variable "vpc_resource_controller_attachment" {
  description = "Dependency on VPC resource controller attachment"
  type        = any
  default     = null
}

variable "eks_worker_node_attachment" {
  description = "Dependency on EKS worker node attachment"
  type        = any
  default     = null
}

variable "eks_cni_attachment" {
  description = "Dependency on EKS CNI attachment"
  type        = any
  default     = null
}

variable "eks_registry_attachment" {
  description = "Dependency on EKS registry attachment"
  type        = any
  default     = null
}

variable "eks_ssm_attachment" {
  description = "Dependency on EKS SSM attachment"
  type        = any
  default     = null
}
