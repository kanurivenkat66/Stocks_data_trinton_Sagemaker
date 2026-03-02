# SageMaker Module - Outputs

output "domain_id" {
  description = "SageMaker Studio domain ID"
  value       = try(aws_sagemaker_domain.studio[0].id, null)
}

output "domain_url" {
  description = "SageMaker Studio domain URL"
  value       = try(aws_sagemaker_domain.studio[0].url, null)
}

output "user_profile_names" {
  description = "SageMaker Studio user profile names"
  value       = [for p in aws_sagemaker_user_profile.profiles : p.user_profile_name]
}

output "transactions_feature_group_name" {
  description = "Name of the transactions Feature Store group"
  value       = try(aws_sagemaker_feature_group.transactions[0].feature_group_name, null)
}

output "customers_feature_group_name" {
  description = "Name of the customers Feature Store group"
  value       = try(aws_sagemaker_feature_group.customers[0].feature_group_name, null)
}

output "model_package_group_name" {
  description = "Name of the model package group (model registry)"
  value       = try(aws_sagemaker_model_package_group.fraud_detection[0].model_package_group_name, null)
}

output "model_package_group_arn" {
  description = "ARN of the model package group"
  value       = try(aws_sagemaker_model_package_group.fraud_detection[0].model_package_group_arn, null)
}
