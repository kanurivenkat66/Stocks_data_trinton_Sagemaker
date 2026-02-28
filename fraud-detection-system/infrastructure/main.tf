# Root Module - Main Infrastructure Orchestration
# This file calls all the individual modules to build the complete infrastructure

# Get current AWS account and region for data sources
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

# ===== VPC Module =====
module "vpc" {
  source = "./modules/vpc"

  project_name             = var.project_name
  vpc_cidr                 = var.vpc_cidr
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_subnet_cidrs     = var.private_subnet_cidrs
  availability_zones       = slice(data.aws_availability_zones.available.names, 0, 3)
  enable_vpc_flow_logs     = var.enable_vpc_flow_logs
  enable_vpc_endpoints     = var.enable_vpc_endpoints
  common_tags              = local.common_tags
}

# ===== IAM Module =====
module "iam" {
  source = "./modules/iam"

  project_name     = var.project_name
  enable_sagemaker = var.enable_sagemaker
  s3_bucket_arns   = module.storage.all_bucket_arns
  oidc_provider_arn = module.eks.oidc_provider_arn
  common_tags      = local.common_tags
}

# ===== Storage Module =====
module "storage" {
  source = "./modules/storage"

  project_name            = var.project_name
  data_retention_days     = var.data_retention_days
  model_retention_days    = var.model_retention_days
  artifacts_retention_days = var.artifacts_retention_days
  log_retention_days      = var.log_retention_days
  common_tags             = local.common_tags
}

# ===== EKS Module =====
module "eks" {
  source = "./modules/eks"

  project_name                    = var.project_name
  kubernetes_version              = var.kubernetes_version
  eks_cluster_role_arn            = module.iam.eks_cluster_role_arn
  eks_node_role_arn               = module.iam.eks_nodes_role_arn
  subnet_ids                      = module.vpc.private_subnet_ids
  eks_security_group_id           = module.vpc.eks_cluster_security_group_id
  endpoint_private_access         = var.endpoint_private_access
  endpoint_public_access          = var.endpoint_public_access
  public_access_cidrs             = var.public_access_cidrs
  enabled_cluster_log_types       = var.enabled_cluster_log_types
  log_retention_days              = var.log_retention_days
  cpu_instance_types              = var.cpu_instance_types
  cpu_desired_size                = var.cpu_desired_size
  cpu_min_size                    = var.cpu_min_size
  cpu_max_size                    = var.cpu_max_size
  enable_gpu                      = var.enable_gpu
  gpu_instance_types              = var.gpu_instance_types
  gpu_desired_size                = var.gpu_desired_size
  gpu_min_size                    = var.gpu_min_size
  gpu_max_size                    = var.gpu_max_size
  node_disk_size                  = var.node_disk_size
  use_spot_instances              = var.use_spot_instances
  vpc_cni_addon_version           = var.vpc_cni_addon_version
  coredns_addon_version           = var.coredns_addon_version
  kube_proxy_addon_version        = var.kube_proxy_addon_version
  ebs_csi_addon_version           = var.ebs_csi_addon_version
  common_tags                     = local.common_tags
  iam_role_policy_attachment      = aws_iam_role_policy_attachment.eks_cluster_policy.id
  vpc_resource_controller_attachment = aws_iam_role_policy_attachment.eks_vpc_resource_controller.id
  eks_worker_node_attachment      = aws_iam_role_policy_attachment.eks_worker_node.id
  eks_cni_attachment              = aws_iam_role_policy_attachment.eks_cni.id
  eks_registry_attachment         = aws_iam_role_policy_attachment.eks_container_registry.id
  eks_ssm_attachment              = aws_iam_role_policy_attachment.eks_ssm.id

  providers = {
    kubernetes = kubernetes
    helm       = helm
    tls        = tls
  }
}

# ===== Helm Releases for KServe and Karpenter =====

# KServe Helm Release
resource "helm_release" "kserve" {
  name             = "kserve"
  namespace        = "kserve"
  create_namespace = true
  repository       = "https://kserve.github.io/charts"
  chart            = "kserve"
  version          = var.kserve_version
  timeout          = 600

  values = [
    yamlencode({
      rbac = {
        serviceAccountCreate = true
      }
      inferenceservice = {
        enabled = true
      }
    })
  ]

  depends_on = [module.eks]
}

# Karpenter Helm Release
resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true
  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = var.karpenter_version
  timeout          = 300

  values = [
    yamlencode({
      serviceAccount = {
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.karpenter.arn
        }
      }
      settings = {
        aws = {
          clusterName       = module.eks.cluster_name
          defaultInstanceProfile = var.project_name
          interruptionQueue = "${var.project_name}-spot-interruption"
        }
      }
    })
  ]

  depends_on = [module.eks]
}

# Create IAM role for Karpenter
resource "aws_iam_role" "karpenter" {
  name_prefix = "${var.project_name}-karpenter-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(module.eks.oidc_provider_url, "https://", "")}:sub" : "system:serviceaccount:karpenter:karpenter"
          }
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-karpenter-role"
    }
  )
}

# Karpenter IAM policies
resource "aws_iam_role_policy_attachment" "karpenter" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  role       = aws_iam_role.karpenter.name
}

resource "aws_iam_role_policy" "karpenter_spot" {
  name = "${var.project_name}-karpenter-spot"
  role = aws_iam_role.karpenter.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:RequestSpotInstances",
          "ec2:CancelSpotInstanceRequests"
        ]
        Resource = "*"
      }
    ]
  })
}

# ===== KServe Module =====
module "kserve" {
  source = "./modules/kserve"

  project_name              = var.project_name
  kserve_role_arn           = module.iam.kserve_role_arn
  models_bucket             = module.storage.models_bucket_id
  predictor_cpu_request     = var.predictor_cpu_request
  predictor_cpu_limit       = var.predictor_cpu_limit
  predictor_memory_request  = var.predictor_memory_request
  predictor_memory_limit    = var.predictor_memory_limit
  predictor_gpu_limit       = var.predictor_gpu_limit
  hpa_min_replicas          = var.hpa_min_replicas
  hpa_max_replicas          = var.hpa_max_replicas
  hpa_target_cpu            = var.hpa_target_cpu
  hpa_target_memory         = var.hpa_target_memory
  enable_monitoring         = var.enable_monitoring
  kserve_helm_release_id    = helm_release.kserve.id

  providers = {
    kubernetes = kubernetes
  }

  depends_on = [helm_release.kserve]
}

# ===== Karpenter Module =====
module "karpenter" {
  source = "./modules/karpenter"

  project_name                = var.project_name
  cluster_name                = module.eks.cluster_name
  # karpenter_role_arn argument removed (no such resource in IAM module)
  karpenter_node_role_name    = module.iam.eks_nodes_role_name
  cpu_instance_types          = var.cpu_instance_types_karpenter
  cpu_pool_max_cpu            = var.cpu_pool_max_cpu
  cpu_pool_max_memory         = var.cpu_pool_max_memory
  enable_gpu_pool             = var.enable_gpu
  gpu_instance_types          = var.gpu_instance_types
  gpu_pool_max_cpu            = var.gpu_pool_max_cpu
  gpu_pool_max_memory         = var.gpu_pool_max_memory
  node_ttl_seconds            = var.node_ttl_seconds
  node_root_volume_size       = var.node_disk_size
  karpenter_helm_release_id   = helm_release.karpenter.id

  providers = {
    kubernetes = kubernetes
  }

  depends_on = [helm_release.karpenter]
}

# ===== IAM Policy Attachments for EKS =====

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = module.iam.eks_cluster_role_name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = module.iam.eks_cluster_role_name
}

resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = module.iam.eks_nodes_role_name
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = module.iam.eks_nodes_role_name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = module.iam.eks_nodes_role_name
}

resource "aws_iam_role_policy_attachment" "eks_ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = module.iam.eks_nodes_role_name
}
