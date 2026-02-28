# Root Module - Variables
# All configurable parameters for the fraud detection infrastructure

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-west-2"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d{1}$", var.aws_region))
    error_message = "AWS region must be valid (e.g., us-west-2)"
  }
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = "fraud-detection"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must be lowercase alphanumeric with hyphens"
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod"
  }
}

# ===== Network Configuration =====

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs for monitoring"
  type        = bool
  default     = true
}

variable "enable_vpc_endpoints" {
  description = "Enable VPC endpoints for S3 and DynamoDB"
  type        = bool
  default     = true
}

# ===== EKS Configuration =====

variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
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
}

variable "cpu_min_size" {
  description = "Minimum number of CPU nodes"
  type        = number
  default     = 1
}

variable "cpu_max_size" {
  description = "Maximum number of CPU nodes"
  type        = number
  default     = 10
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
}

variable "node_disk_size" {
  description = "EBS volume size for nodes in GB"
  type        = number
  default     = 100
}

variable "use_spot_instances" {
  description = "Use Spot instances for cost savings"
  type        = bool
  default     = true
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
  description = "CIDR blocks with access to public endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enabled_cluster_log_types" {
  description = "Control plane logging types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

# ===== Storage Configuration =====

variable "data_retention_days" {
  description = "Days to keep old data versions"
  type        = number
  default     = 90
}

variable "model_retention_days" {
  description = "Days to keep old model versions"
  type        = number
  default     = 180
}

variable "artifacts_retention_days" {
  description = "Days to keep training artifacts"
  type        = number
  default     = 60
}

# ===== KServe Configuration =====

variable "kserve_version" {
  description = "KServe Helm chart version"
  type        = string
  default     = "0.10.0"
}

variable "predictor_cpu_request" {
  description = "CPU request for Triton predictor"
  type        = string
  default     = "500m"
}

variable "predictor_cpu_limit" {
  description = "CPU limit for Triton predictor"
  type        = string
  default     = "2"
}

variable "predictor_memory_request" {
  description = "Memory request for Triton predictor"
  type        = string
  default     = "1Gi"
}

variable "predictor_memory_limit" {
  description = "Memory limit for Triton predictor"
  type        = string
  default     = "4Gi"
}

variable "predictor_gpu_limit" {
  description = "GPU limit for Triton predictor"
  type        = number
  default     = 1
}

variable "hpa_min_replicas" {
  description = "Minimum replicas for HPA"
  type        = number
  default     = 3
}

variable "hpa_max_replicas" {
  description = "Maximum replicas for HPA"
  type        = number
  default     = 10
}

variable "hpa_target_cpu" {
  description = "Target CPU utilization for HPA"
  type        = number
  default     = 80
}

variable "hpa_target_memory" {
  description = "Target memory utilization for HPA"
  type        = number
  default     = 80
}

# ===== Karpenter Configuration =====

variable "karpenter_version" {
  description = "Karpenter Helm chart version"
  type        = string
  default     = "v0.32.0"
}

variable "cpu_instance_types_karpenter" {
  description = "CPU instance types for Karpenter"
  type        = list(string)
  default     = ["t3.large", "t3.xlarge", "t3.2xlarge"]
}

variable "cpu_pool_max_cpu" {
  description = "Maximum CPUs for CPU pool"
  type        = string
  default     = "1000"
}

variable "cpu_pool_max_memory" {
  description = "Maximum memory for CPU pool"
  type        = string
  default     = "1000Gi"
}

variable "gpu_pool_max_cpu" {
  description = "Maximum CPUs for GPU pool"
  type        = string
  default     = "100"
}

variable "gpu_pool_max_memory" {
  description = "Maximum memory for GPU pool"
  type        = string
  default     = "500Gi"
}

variable "node_ttl_seconds" {
  description = "Seconds before removing idle nodes"
  type        = number
  default     = 2592000  # 30 days
}

# ===== SageMaker Configuration =====

variable "enable_sagemaker" {
  description = "Enable SageMaker roles and policies"
  type        = bool
  default     = true
}

# ===== Monitoring Configuration =====

variable "enable_monitoring" {
  description = "Enable Prometheus and Grafana monitoring"
  type        = bool
  default     = true
}

# ===== Addon Versions =====

variable "vpc_cni_addon_version" {
  description = "Version of VPC CNI addon"
  type        = string
  default     = "v1.14.1-eksbuild.1"
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
