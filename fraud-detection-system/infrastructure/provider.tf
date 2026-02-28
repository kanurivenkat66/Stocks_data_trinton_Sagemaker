terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
  
  # Backend configuration - S3 backend for remote state
  backend "s3" {
    bucket         = "fraud-detection-terraform-state-889526028446"
    key            = "fraud-detection/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      CreatedAt   = timestamp()
    }
  }
}

# Configure Kubernetes provider for EKS
# This provider is auto-configured for each module that needs it
provider "kubernetes" {
  alias = "default"
}

# Configure Helm provider for Kubernetes charts
# This provider is auto-configured for each module that needs it
provider "helm" {
  alias = "default"
}
