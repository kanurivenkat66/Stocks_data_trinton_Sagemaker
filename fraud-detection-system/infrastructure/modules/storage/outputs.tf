# Storage Module - Outputs

output "data_bucket_id" {
  description = "ID/name of the data S3 bucket"
  value       = aws_s3_bucket.data.id
}

output "data_bucket_arn" {
  description = "ARN of the data S3 bucket"
  value       = aws_s3_bucket.data.arn
}

output "models_bucket_id" {
  description = "ID/name of the models S3 bucket"
  value       = aws_s3_bucket.models.id
}

output "models_bucket_arn" {
  description = "ARN of the models S3 bucket"
  value       = aws_s3_bucket.models.arn
}

output "training_artifacts_bucket_id" {
  description = "ID/name of the training artifacts S3 bucket"
  value       = aws_s3_bucket.training_artifacts.id
}

output "training_artifacts_bucket_arn" {
  description = "ARN of the training artifacts S3 bucket"
  value       = aws_s3_bucket.training_artifacts.arn
}

output "logs_bucket_id" {
  description = "ID/name of the logs S3 bucket"
  value       = aws_s3_bucket.logs.id
}

output "logs_bucket_arn" {
  description = "ARN of the logs S3 bucket"
  value       = aws_s3_bucket.logs.arn
}

output "all_bucket_arns" {
  description = "List of all S3 bucket ARNs"
  value = [
    aws_s3_bucket.data.arn,
    aws_s3_bucket.models.arn,
    aws_s3_bucket.training_artifacts.arn,
    aws_s3_bucket.logs.arn
  ]
}

output "all_bucket_ids" {
  description = "List of all S3 bucket IDs"
  value = [
    aws_s3_bucket.data.id,
    aws_s3_bucket.models.id,
    aws_s3_bucket.training_artifacts.id,
    aws_s3_bucket.logs.id
  ]
}
