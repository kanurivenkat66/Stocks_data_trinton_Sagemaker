# Root Module - Outputs
# Critical values for operating the fraud detection system

# ===== VPC Outputs =====

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_ips" {
  description = "NAT Gateway public IPs"
  value       = module.vpc.nat_gateway_ips
}

# ===== EKS Cluster Outputs =====

output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
  sensitive   = false
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "Kubernetes version"
  value       = module.eks.cluster_version
}

output "cluster_ca_certificate" {
  description = "Base64 encoded CA certificate for TLS"
  value       = module.eks.cluster_ca_certificate
  sensitive   = true
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  value       = module.eks.oidc_provider_arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC provider"
  value       = module.eks.oidc_provider_url
}

# ===== Node Group Outputs =====

output "cpu_node_group_id" {
  description = "CPU node group ID"
  value       = module.eks.cpu_node_group_id
}

output "cpu_node_group_status" {
  description = "CPU node group status"
  value       = module.eks.cpu_node_group_status
}

output "gpu_node_group_id" {
  description = "GPU node group ID"
  value       = module.eks.gpu_node_group_id
}

output "gpu_node_group_status" {
  description = "GPU node group status"
  value       = module.eks.gpu_node_group_status
}

# ===== Storage Outputs =====

output "data_bucket" {
  description = "Data S3 bucket name"
  value       = module.storage.data_bucket_id
}

output "models_bucket" {
  description = "Models S3 bucket name"
  value       = module.storage.models_bucket_id
}

output "training_artifacts_bucket" {
  description = "Training artifacts S3 bucket name"
  value       = module.storage.training_artifacts_bucket_id
}

output "logs_bucket" {
  description = "Logs S3 bucket name"
  value       = module.storage.logs_bucket_id
}

output "all_bucket_arns" {
  description = "ARNs of all S3 buckets"
  value       = module.storage.all_bucket_arns
  sensitive   = true
}

# ===== IAM Outputs =====

output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster role"
  value       = module.iam.eks_cluster_role_arn
}

output "eks_nodes_role_arn" {
  description = "ARN of the EKS nodes role"
  value       = module.iam.eks_nodes_role_arn
}

output "kserve_role_arn" {
  description = "ARN of the KServe IRSA role"
  value       = module.iam.kserve_role_arn
}

output "sagemaker_role_arn" {
  description = "ARN of the SageMaker role"
  value       = module.iam.sagemaker_role_arn
}

# ===== KServe Outputs =====

output "kserve_namespace" {
  description = "Kubernetes namespace for KServe"
  value       = module.kserve.kserve_namespace
}

output "kserve_service_account" {
  description = "Kubernetes service account for KServe"
  value       = module.kserve.kserve_service_account
}


# ===== Karpenter Outputs =====

output "karpenter_namespace" {
  description = "Kubernetes namespace for Karpenter"
  value       = module.karpenter.karpenter_namespace
}

output "cpu_nodepool_name" {
  description = "Karpenter CPU NodePool name"
  value       = module.karpenter.cpu_nodepool_name
}

output "gpu_nodepool_name" {
  description = "Karpenter GPU NodePool name"
  value       = module.karpenter.gpu_nodepool_name
}

# ===== Connection Information =====

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "get_token" {
  description = "Command to get authentication token"
  value       = "aws eks get-token --cluster-name ${module.eks.cluster_name} --region ${var.aws_region}"
}

# ===== Summary =====

output "deployment_summary" {
  description = "Deployment summary"
  value = <<-EOT
    
    ╔══════════════════════════════════════════════════════════════╗
    ║               DEPLOYMENT COMPLETE                            ║
    ╚══════════════════════════════════════════════════════════════╝
    
    Cluster:
      Name: ${module.eks.cluster_name}
      Endpoint: ${module.eks.cluster_endpoint}
      Region: ${var.aws_region}
      
    Node Groups:
      CPU: ${module.eks.cpu_node_group_status}
      GPU: ${try(module.eks.gpu_node_group_status, "Disabled")}
      
    Storage:
      Data Bucket: ${module.storage.data_bucket_id}
      Models Bucket: ${module.storage.models_bucket_id}
      Artifacts Bucket: ${module.storage.training_artifacts_bucket_id}
      
    Model Serving:
      KServe Namespace: ${module.kserve.kserve_namespace}
      
    Auto-scaling:
      Karpenter Namespace: ${module.karpenter.karpenter_namespace}
      CPU Pool: ${coalesce(module.karpenter.cpu_nodepool_name, "pending")}
      GPU Pool: ${coalesce(module.karpenter.gpu_nodepool_name, "pending")}
      
    To connect to the cluster:
      $ aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}
      $ kubectl get nodes
      
  EOT
  sensitive   = false
}
