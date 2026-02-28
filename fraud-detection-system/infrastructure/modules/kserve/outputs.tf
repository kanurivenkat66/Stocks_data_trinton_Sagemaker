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

output "inference_service_name" {
  description = "Name of the InferenceService"
  value       = kubernetes_manifest.triton_inference_service.manifest.metadata.name
}

output "hpa_name" {
  description = "Name of the HorizontalPodAutoscaler"
  value       = kubernetes_horizontal_pod_autoscaler_v2.kserve.metadata[0].name
}
