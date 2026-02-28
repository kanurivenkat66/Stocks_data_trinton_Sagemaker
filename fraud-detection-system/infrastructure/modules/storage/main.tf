# Storage Module - S3 Buckets for Data, Models, Logs, etc.

# Locals for bucket configuration
locals {
  bucket_names = {
    data                = "${var.project_name}-data"
    models              = "${var.project_name}-models"
    training_artifacts  = "${var.project_name}-training-artifacts"
    logs                = "${var.project_name}-logs"
  }
}

# Data Bucket
resource "aws_s3_bucket" "data" {
  bucket = "${local.bucket_names.data}-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-data-bucket"
    }
  )
}

# Models Bucket
resource "aws_s3_bucket" "models" {
  bucket = "${local.bucket_names.models}-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-models-bucket"
    }
  )
}

# Training Artifacts Bucket
resource "aws_s3_bucket" "training_artifacts" {
  bucket = "${local.bucket_names.training_artifacts}-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-training-artifacts-bucket"
    }
  )
}

# Logs Bucket
resource "aws_s3_bucket" "logs" {
  bucket = "${local.bucket_names.logs}-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-logs-bucket"
    }
  )
}

# ===== Encryption Configuration =====

# Data bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Models bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "models" {
  bucket = aws_s3_bucket.models.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Training artifacts bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "training_artifacts" {
  bucket = aws_s3_bucket.training_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Logs bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ===== Versioning Configuration =====

resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "models" {
  bucket = aws_s3_bucket.models.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "training_artifacts" {
  bucket = aws_s3_bucket.training_artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ===== Public Access Block (Security) =====

resource "aws_s3_bucket_public_access_block" "data" {
  bucket = aws_s3_bucket.data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "models" {
  bucket = aws_s3_bucket.models.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "training_artifacts" {
  bucket = aws_s3_bucket.training_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ===== Bucket Logging =====

resource "aws_s3_bucket_logging" "data" {
  bucket = aws_s3_bucket.data.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "data-bucket-logs/"
}

resource "aws_s3_bucket_logging" "models" {
  bucket = aws_s3_bucket.models.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "models-bucket-logs/"
}

resource "aws_s3_bucket_logging" "training_artifacts" {
  bucket = aws_s3_bucket.training_artifacts.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "training-artifacts-bucket-logs/"
}

# ===== Lifecycle Policies (Cost Optimization) =====

resource "aws_s3_bucket_lifecycle_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    id     = "archive-old-versions"
    status = "Enabled"
    filter {}

    noncurrent_version_expiration {
      noncurrent_days = var.data_retention_days
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "models" {
  bucket = aws_s3_bucket.models.id

  rule {
    id     = "keep-versions"
    status = "Enabled"
    filter {}

    noncurrent_version_expiration {
      noncurrent_days = var.model_retention_days
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "training_artifacts" {
  bucket = aws_s3_bucket.training_artifacts.id

  rule {
    id     = "archive-old-artifacts"
    status = "Enabled"
    filter {}

    noncurrent_version_expiration {
      noncurrent_days = var.artifacts_retention_days
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "expire-logs"
    status = "Enabled"
    filter {}

    expiration {
      days = var.log_retention_days
    }
  }
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}
