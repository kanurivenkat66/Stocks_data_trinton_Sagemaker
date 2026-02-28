# Karpenter Module - Autoscaling Configuration

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
  }
}

# Karpenter Namespace
resource "kubernetes_namespace" "karpenter" {
  metadata {
    name = "karpenter"
    labels = {
      "app.kubernetes.io/name" = "karpenter"
    }
  }
}

# Service Account for Karpenter (with IRSA)
resource "kubernetes_service_account" "karpenter" {
  metadata {
    name      = "karpenter"
    namespace = kubernetes_namespace.karpenter.metadata[0].name

    annotations = {
      "eks.amazonaws.com/role-arn" = var.karpenter_role_arn
    }
  }
}

# Karpenter NodePool for CPU workloads
resource "kubernetes_manifest" "karpenter_cpu_nodepool" {
  count = var.cluster_exists ? 1 : 0
  manifest = {
    apiVersion = "karpenter.sh/v1beta1"
    kind       = "NodePool"
    metadata = {
      name      = "${var.project_name}-cpu-pool"
      namespace = kubernetes_namespace.karpenter.metadata[0].name
    }
    spec = {
      template = {
        spec = {
          requirements = [
            {
              key      = "karpenter.sh/cpu"
              operator = "In"
              values   = var.cpu_instance_types
            },
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["spot", "on-demand"]
            },
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64"]
            }
          ]
          nodeClassRef = {
            name = "default"
          }
        }
      }
      limits = {
        resources = {
          cpu    = var.cpu_pool_max_cpu
          memory = var.cpu_pool_max_memory
        }
      }
      consolidationPolicy = {
        nodes = "underutilized"
      }
      ttlSecondsAfterEmpty = 30
      ttlSecondsUntilExpired = var.node_ttl_seconds
    }
  }

  depends_on = [var.karpenter_helm_release_id]
}

# Karpenter NodePool for GPU workloads
resource "kubernetes_manifest" "karpenter_gpu_nodepool" {
  count = var.cluster_exists && var.enable_gpu_pool ? 1 : 0

  manifest = {
    apiVersion = "karpenter.sh/v1beta1"
    kind       = "NodePool"
    metadata = {
      name      = "${var.project_name}-gpu-pool"
      namespace = kubernetes_namespace.karpenter.metadata[0].name
    }
    spec = {
      template = {
        spec = {
          requirements = [
            {
              key      = "karpenter.sh/gpu"
              operator = "In"
              values   = ["true"]
            },
            {
              key      = "karpenter.sh/gpu-name"
              operator = "In"
              values   = var.gpu_instance_types
            },
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["spot", "on-demand"]
            }
          ]
          nodeClassRef = {
            name = "default"
          }
          taints = [
            {
              key    = "nvidia.com/gpu"
              value  = "true"
              effect = "NoSchedule"
            }
          ]
        }
      }
      limits = {
        resources = {
          cpu    = var.gpu_pool_max_cpu
          memory = var.gpu_pool_max_memory
        }
      }
      consolidationPolicy = {
        nodes = "underutilized"
      }
      ttlSecondsAfterEmpty   = 60
      ttlSecondsUntilExpired = var.node_ttl_seconds
    }
  }

  depends_on = [var.karpenter_helm_release_id]
}

# EC2NodeClass for resource configuration
resource "kubernetes_manifest" "ec2_node_class" {
  count = var.cluster_exists ? 1 : 0
  manifest = {
    apiVersion = "karpenter.k8s.aws/v1beta1"
    kind       = "EC2NodeClass"
    metadata = {
      name      = "default"
      namespace = kubernetes_namespace.karpenter.metadata[0].name
    }
    spec = {
      amiFamily = "AL2"
      role      = var.karpenter_node_role_name
      subnetSelector = {
        "karpenter.sh/discovery" = var.cluster_name
      }
      securityGroupSelector = {
        "karpenter.sh/discovery" = var.cluster_name
      }
      tags = {
        ManagedBy = "Karpenter"
        Project   = var.project_name
      }
      blockDeviceMappings = [
        {
          deviceName = "/dev/xvda"
          ebs = {
            volumeSize            = var.node_root_volume_size
            volumeType            = "gp3"
            deleteOnTermination   = true
            encrypted             = true
            iops                  = 3000
            throughput            = 125
          }
        }
      ]
      metadataOptions = {
        httpEndpoint            = "enabled"
        httpProtocolIPv6        = "disabled"
        httpPutResponseHopLimit = 2
        httpTokens              = "required"
      }
    }
  }

  depends_on = [var.karpenter_helm_release_id]
}

# PodDisruptionBudget for Karpenter controller
resource "kubernetes_pod_disruption_budget_v1" "karpenter" {
  metadata {
    name      = "karpenter"
    namespace = kubernetes_namespace.karpenter.metadata[0].name
  }

  spec {
    min_available = 1

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "karpenter"
      }
    }
  }
}
