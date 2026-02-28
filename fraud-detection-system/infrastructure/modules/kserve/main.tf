# KServe Module - Model Serving Infrastructure

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
  }
}

# KServe Namespace
resource "kubernetes_namespace" "kserve" {
  metadata {
    name = "kserve-inference"
    labels = {
      "app.kubernetes.io/name" = "kserve"
    }
  }
}

# KServe Service Account
resource "kubernetes_service_account" "kserve" {
  metadata {
    name      = "kserve-sa"
    namespace = kubernetes_namespace.kserve.metadata[0].name

    annotations = {
      "eks.amazonaws.com/role-arn" = var.kserve_role_arn
    }
  }
}

# Knative Serving Namespace (KServe depends on it)
resource "kubernetes_namespace" "knative_serving" {
  metadata {
    name = "knative-serving"
  }
}

# InferenceService CRD - For Triton server configuration
resource "kubernetes_manifest" "triton_inference_service" {
  manifest = {
    apiVersion = "serving.kserve.io/v1beta1"
    kind       = "InferenceService"
    metadata = {
      name      = "${var.project_name}-triton"
      namespace = kubernetes_namespace.kserve.metadata[0].name
    }
    spec = {
      predictor = {
        serviceAccountName = kubernetes_service_account.kserve.metadata[0].name
        triton = {
          storageUri = "s3://${var.models_bucket}/"
          resources = {
            limits = {
              cpu    = var.predictor_cpu_limit
              memory = var.predictor_memory_limit
              nvidia.com/gpu : var.predictor_gpu_limit > 0 ? var.predictor_gpu_limit : null
            }
            requests = {
              cpu    = var.predictor_cpu_request
              memory = var.predictor_memory_request
            }
          }
        }
      }
      canaryTrafficPercent = 0
    }
  }

  depends_on = [
    kubernetes_service_account.kserve,
    var.kserve_helm_release_id
  ]
}

# HPA for KServe inference service
resource "kubernetes_horizontal_pod_autoscaler_v2" "kserve" {
  metadata {
    name      = "${var.project_name}-triton-hpa"
    namespace = kubernetes_namespace.kserve.metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = "${var.project_name}-triton-predictor-default"
    }

    min_replicas = var.hpa_min_replicas
    max_replicas = var.hpa_max_replicas

    metric {
      type = "Resource"
      resource = {
        name = "cpu"
        target = {
          type                = "Utilization"
          average_utilization = var.hpa_target_cpu
        }
      }
    }

    metric {
      type = "Resource"
      resource = {
        name = "memory"
        target = {
          type                = "Utilization"
          average_utilization = var.hpa_target_memory
        }
      }
    }
  }
}

# Network Policy for KServe (security)
resource "kubernetes_network_policy" "kserve" {
  metadata {
    name      = "${var.project_name}-kserve-netpolicy"
    namespace = kubernetes_namespace.kserve.metadata[0].name
  }

  spec {
    pod_selector = {
      match_labels = {
        "app.kubernetes.io/name" = "kserve"
      }
    }

    policy_types = ["Ingress", "Egress"]

    # Allow ingress from any pod in the cluster
    ingress {
      from {
        pod_selector = {}
      }
      ports {
        protocol = "TCP"
        port     = "8080"
      }
    }

    # Allow DNS egress
    egress {
      to {
        namespace_selector = {
          match_labels = {
            name = "kube-system"
          }
        }
      }
      ports {
        protocol = "UDP"
        port     = "53"
      }
    }

    # Allow S3 egress
    egress {
      to {
        pod_selector = {}
      }
      ports {
        protocol = "TCP"
        port     = "443"
      }
    }
  }
}

# ServiceMonitor for Prometheus (if monitoring enabled)
resource "kubernetes_manifest" "kserve_service_monitor" {
  count = var.enable_monitoring ? 1 : 0

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "${var.project_name}-kserve-monitor"
      namespace = kubernetes_namespace.kserve.metadata[0].name
    }
    spec = {
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "kserve"
        }
      }
      endpoints = [
        {
          port = "metrics"
        }
      ]
    }
  }
}
