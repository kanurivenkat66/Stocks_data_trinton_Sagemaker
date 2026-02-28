# Karpenter Module - Outputs

output "karpenter_namespace" {
  description = "Kubernetes namespace for Karpenter"
  value       = kubernetes_namespace.karpenter.metadata[0].name
}

output "karpenter_service_account" {
  description = "Kubernetes service account for Karpenter"
  value       = kubernetes_service_account.karpenter.metadata[0].name
}

output "cpu_nodepool_name" {
  description = "Name of the CPU NodePool"
  value       = try(kubernetes_manifest.karpenter_cpu_nodepool[0].manifest.metadata.name, null)
}

output "gpu_nodepool_name" {
  description = "Name of the GPU NodePool (if enabled)"
  value       = try(kubernetes_manifest.karpenter_gpu_nodepool[0].manifest.metadata.name, null)
}

output "ec2_node_class_name" {
  description = "Name of the EC2NodeClass"
  value       = try(kubernetes_manifest.ec2_node_class[0].manifest.metadata.name, null)
}
