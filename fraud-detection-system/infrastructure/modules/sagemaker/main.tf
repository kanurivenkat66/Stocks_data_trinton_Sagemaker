# SageMaker Module - Resources

locals {
  studio_enabled         = var.enabled && var.enable_studio
  feature_store_enabled  = var.enabled && var.enable_feature_store
  model_registry_enabled = var.enabled && var.enable_model_registry
}

# ===== SageMaker Studio Domain =====

resource "aws_sagemaker_domain" "studio" {
  count = local.studio_enabled ? 1 : 0

  domain_name = "${var.project_name}-studio"
  auth_mode   = "IAM"
  vpc_id      = var.vpc_id
  subnet_ids  = var.subnet_ids

  default_user_settings {
    execution_role  = var.execution_role_arn
    security_groups = var.vpc_security_group_ids

    sharing_settings {
      notebook_output_option = "Disabled"
    }
  }

  app_network_access_type = "VpcOnly"

  retention_policy {
    home_efs_file_system = "Retain"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-studio"
  })
}

# Studio User Profiles
resource "aws_sagemaker_user_profile" "profiles" {
  for_each = local.studio_enabled ? toset(var.studio_user_profiles) : toset([])

  domain_id         = aws_sagemaker_domain.studio[0].id
  user_profile_name = each.value

  user_settings {
    execution_role  = var.execution_role_arn
    security_groups = var.vpc_security_group_ids
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${each.value}"
  })
}

# ===== SageMaker Feature Store =====

# Feature Group: Transaction features for real-time fraud scoring
resource "aws_sagemaker_feature_group" "transactions" {
  count = local.feature_store_enabled ? 1 : 0

  feature_group_name             = "${var.project_name}-transactions"
  record_identifier_feature_name = "transaction_id"
  event_time_feature_name        = "event_time"
  role_arn                       = var.execution_role_arn
  description                    = "Real-time transaction features for fraud detection"

  feature_definition {
    feature_name = "transaction_id"
    feature_type = "String"
  }

  feature_definition {
    feature_name = "event_time"
    feature_type = "Fractional"
  }

  feature_definition {
    feature_name = "amount"
    feature_type = "Fractional"
  }

  feature_definition {
    feature_name = "merchant_id"
    feature_type = "String"
  }

  feature_definition {
    feature_name = "customer_id"
    feature_type = "String"
  }

  feature_definition {
    feature_name = "card_type"
    feature_type = "String"
  }

  feature_definition {
    feature_name = "merchant_category"
    feature_type = "String"
  }

  feature_definition {
    feature_name = "is_online"
    feature_type = "Integral"
  }

  feature_definition {
    feature_name = "device_type"
    feature_type = "String"
  }

  feature_definition {
    feature_name = "country_code"
    feature_type = "String"
  }

  online_store_config {
    enable_online_store = true
  }

  offline_store_config {
    s3_storage_config {
      s3_uri = "s3://${var.feature_store_s3_bucket}/feature-store/transactions"
    }
    disable_glue_table_creation = false
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-transactions-fg"
  })
}

# Feature Group: Customer aggregate features for fraud detection
resource "aws_sagemaker_feature_group" "customers" {
  count = local.feature_store_enabled ? 1 : 0

  feature_group_name             = "${var.project_name}-customers"
  record_identifier_feature_name = "customer_id"
  event_time_feature_name        = "event_time"
  role_arn                       = var.execution_role_arn
  description                    = "Customer aggregate features for fraud detection"

  feature_definition {
    feature_name = "customer_id"
    feature_type = "String"
  }

  feature_definition {
    feature_name = "event_time"
    feature_type = "Fractional"
  }

  feature_definition {
    feature_name = "account_age_days"
    feature_type = "Integral"
  }

  feature_definition {
    feature_name = "avg_transaction_amount_30d"
    feature_type = "Fractional"
  }

  feature_definition {
    feature_name = "transaction_count_30d"
    feature_type = "Integral"
  }

  feature_definition {
    feature_name = "fraud_count_90d"
    feature_type = "Integral"
  }

  feature_definition {
    feature_name = "card_count"
    feature_type = "Integral"
  }

  feature_definition {
    feature_name = "distinct_merchant_count_30d"
    feature_type = "Integral"
  }

  feature_definition {
    feature_name = "max_transaction_amount_7d"
    feature_type = "Fractional"
  }

  online_store_config {
    enable_online_store = true
  }

  offline_store_config {
    s3_storage_config {
      s3_uri = "s3://${var.feature_store_s3_bucket}/feature-store/customers"
    }
    disable_glue_table_creation = false
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-customers-fg"
  })
}

# ===== SageMaker Model Registry =====

resource "aws_sagemaker_model_package_group" "fraud_detection" {
  count = local.model_registry_enabled ? 1 : 0

  model_package_group_name        = "${var.project_name}-models"
  model_package_group_description = "Model registry for fraud detection models (XGBoost, LightGBM)"

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-model-registry"
  })
}
