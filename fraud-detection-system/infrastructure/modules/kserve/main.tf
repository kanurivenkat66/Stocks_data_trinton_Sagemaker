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
  }
}

# KServe Service Account with IRSA
resource "kubernetes_service_account" "kserve" {
  metadata {
    name      = "kserve-sa"
    namespace = kubernetes_namespace.kserve.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = var.kserve_role_arn
    }
  }
}

# Knative Serving Namespace (KServe prerequisite)
resource "kubernetes_namespace" "knative_serving" {
  metadata {
    name = "knative-serving"
  }
}
