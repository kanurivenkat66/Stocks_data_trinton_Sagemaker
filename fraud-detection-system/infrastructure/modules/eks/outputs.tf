# EKS Module - Outputs

output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "Kubernetes version running on cluster"
  value       = aws_eks_cluster.main.version
}

output "cluster_ca_certificate" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider"
  value       = aws_iam_openid_connect_provider.cluster.arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC Provider"
  value       = aws_iam_openid_connect_provider.cluster.url
}

output "cpu_node_group_id" {
  description = "EKS CPU node group ID"
  value       = aws_eks_node_group.cpu.id
}

output "cpu_node_group_status" {
  description = "EKS CPU node group status"
  value       = aws_eks_node_group.cpu.status
}

output "gpu_node_group_id" {
  description = "EKS GPU node group ID (if enabled)"
  value       = try(aws_eks_node_group.gpu[0].id, null)
}

output "gpu_node_group_status" {
  description = "EKS GPU node group status (if enabled)"
  value       = try(aws_eks_node_group.gpu[0].status, null)
}

output "alb_controller_role_arn" {
  description = "ARN of the AWS Load Balancer Controller role"
  value       = aws_iam_role.aws_load_balancer_controller.arn
}

output "cluster_log_group" {
  description = "CloudWatch log group name for EKS cluster logs"
  value       = try(aws_cloudwatch_log_group.eks[0].name, null)
}
