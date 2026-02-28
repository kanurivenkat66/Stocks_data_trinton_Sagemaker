# IAM Module - Outputs

output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster role"
  value       = aws_iam_role.eks_cluster.arn
}

output "eks_cluster_role_name" {
  description = "Name of the EKS cluster role"
  value       = aws_iam_role.eks_cluster.name
}

output "eks_nodes_role_arn" {
  description = "ARN of the EKS nodes role"
  value       = aws_iam_role.eks_nodes.arn
}

output "eks_nodes_role_name" {
  description = "Name of the EKS nodes role"
  value       = aws_iam_role.eks_nodes.name
}

output "eks_nodes_instance_profile_arn" {
  description = "ARN of the EKS nodes instance profile"
  value       = aws_iam_instance_profile.eks_nodes.arn
}

output "sagemaker_role_arn" {
  description = "ARN of the SageMaker role (if enabled)"
  value       = try(aws_iam_role.sagemaker[0].arn, null)
}

output "sagemaker_role_name" {
  description = "Name of the SageMaker role (if enabled)"
  value       = try(aws_iam_role.sagemaker[0].name, null)
}

output "kserve_role_arn" {
  description = "ARN of the KServe IRSA role"
  value       = aws_iam_role.kserve.arn
}

output "kserve_role_name" {
  description = "Name of the KServe IRSA role"
  value       = aws_iam_role.kserve.name
}

output "eks_cloudwatch_role_arn" {
  description = "ARN of the EKS CloudWatch logs role"
  value       = aws_iam_role.eks_cloudwatch.arn
}
