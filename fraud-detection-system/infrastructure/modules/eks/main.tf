# EKS Module - Kubernetes Cluster Management

terraform {
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-cluster"
  role_arn = var.eks_cluster_role_arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs
    security_group_ids      = [var.eks_security_group_id]
  }

  # Enable control plane logging
  enabled_cluster_log_types = var.enabled_cluster_log_types

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-cluster"
    }
  )

  depends_on = [
    var.iam_role_policy_attachment,
    var.vpc_resource_controller_attachment
  ]
}

# CloudWatch Log Group for EKS cluster logs
resource "aws_cloudwatch_log_group" "eks" {
  count             = length(var.enabled_cluster_log_types) > 0 ? 1 : 0
  name              = "/aws/eks/${var.project_name}-cluster/cluster"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-eks-logs"
    }
  )
}

# OIDC Provider for IRSA (IAM Roles for Service Accounts)
data "tls_certificate" "cluster" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-eks-irsa"
    }
  )
}

# CPU Node Group (t3 instances)
resource "aws_eks_node_group" "cpu" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-cpu-nodes"
  node_role_arn   = var.eks_node_role_arn
  subnet_ids      = var.subnet_ids
  version         = var.kubernetes_version

  scaling_config {
    desired_size = var.cpu_desired_size
    max_size     = var.cpu_max_size
    min_size     = var.cpu_min_size
  }

  instance_types = var.cpu_instance_types

  # Use Spot instances for cost savings
  capacity_type = var.use_spot_instances ? "SPOT" : "ON_DEMAND"

  disk_size = var.node_disk_size

  # Update strategy
  update_config {
    max_unavailable_percentage = 25
  }

  labels = {
    NodeType = "CPU"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-cpu-nodes"
    }
  )

  depends_on = [
    var.eks_worker_node_attachment,
    var.eks_cni_attachment,
    var.eks_registry_attachment,
    var.eks_ssm_attachment
  ]
}

# GPU Node Group (g4dn instances for inference)
resource "aws_eks_node_group" "gpu" {
  count           = var.enable_gpu ? 1 : 0
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-gpu-nodes"
  node_role_arn   = var.eks_node_role_arn
  subnet_ids      = var.subnet_ids
  version         = var.kubernetes_version

  scaling_config {
    desired_size = var.gpu_desired_size
    max_size     = var.gpu_max_size
    min_size     = var.gpu_min_size
  }

  instance_types = var.gpu_instance_types

  capacity_type = var.use_spot_instances ? "SPOT" : "ON_DEMAND"

  disk_size = var.node_disk_size

  update_config {
    max_unavailable_percentage = 25
  }

  labels = {
    NodeType = "GPU"
  }

  taints = [
    {
      key    = "nvidia.com/gpu"
      value  = "true"
      effect = "NO_SCHEDULE"
    }
  ]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-gpu-nodes"
    }
  )

  depends_on = [
    var.eks_worker_node_attachment,
    var.eks_cni_attachment,
    var.eks_registry_attachment,
    var.eks_ssm_attachment
  ]
}

# EKS Addon - VPC CNI
resource "aws_eks_addon" "vpc_cni" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "vpc-cni"
  addon_version            = var.vpc_cni_addon_version
  resolve_conflicts_on_create = "OVERWRITE"
  service_account_role_arn = var.vpc_cni_role_arn

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-vpc-cni"
    }
  )
}

# EKS Addon - CoreDNS
resource "aws_eks_addon" "coredns" {
  cluster_name            = aws_eks_cluster.main.name
  addon_name              = "coredns"
  addon_version           = var.coredns_addon_version
  resolve_conflicts_on_create = "OVERWRITE"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-coredns"
    }
  )
}

# EKS Addon - kube-proxy
resource "aws_eks_addon" "kube_proxy" {
  cluster_name            = aws_eks_cluster.main.name
  addon_name              = "kube-proxy"
  addon_version           = var.kube_proxy_addon_version
  resolve_conflicts_on_create = "OVERWRITE"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-kube-proxy"
    }
  )
}

# EKS Addon - EBS CSI Driver (for persistent volumes)
resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "ebs-csi-driver"
  addon_version            = var.ebs_csi_addon_version
  resolve_conflicts_on_create = "OVERWRITE"
  service_account_role_arn = var.ebs_csi_role_arn

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-ebs-csi"
    }
  )
}

# AWS Load Balancer Controller - requires external helm provider in root module
resource "aws_iam_role" "aws_load_balancer_controller" {
  name_prefix = "${var.project_name}-alb-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.cluster.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:sub" : "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-alb-controller"
    }
  )
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
  role       = aws_iam_role.aws_load_balancer_controller.name
}
