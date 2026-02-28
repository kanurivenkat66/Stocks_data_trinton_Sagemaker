# KServe Module - Outputs

output "kserve_namespace" {
  description = "Kubernetes namespace for KServe"
  value       = kubernetes_namespace.kserve.metadata[0].name
}

output "kserve_service_account" {
  description = "Kubernetes service account for KServe"
  value       = kubernetes_service_account.kserve.metadata[0].name
}

output "knative_serving_namespace" {
  description = "Kubernetes namespace for Knative Serving"
  value       = kubernetes_namespace.knative_serving.metadata[0].name
}

