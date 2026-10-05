output "cloudfront_domain_name" {
  description = "Public site URL (https://<value>)."
  value       = module.serverless_app.cloudfront_domain_name
}

output "cloudfront_distribution_id" {
  description = "Used by the deploy workflow for cache invalidation."
  value       = module.serverless_app.cloudfront_distribution_id
}

output "site_bucket_name" {
  description = "Deploy workflow syncs web/ into this bucket."
  value       = module.serverless_app.site_bucket_name
}

output "api_endpoint" {
  description = "HTTP API invoke URL."
  value       = module.serverless_app.api_endpoint
}

output "cognito_user_pool_id" {
  description = "Frontend auth config."
  value       = module.serverless_app.cognito_user_pool_id
}

output "cognito_user_pool_client_id" {
  description = "Frontend auth config."
  value       = module.serverless_app.cognito_user_pool_client_id
}

output "dynamodb_table_name" {
  description = "Single-table DynamoDB table."
  value       = module.serverless_app.dynamodb_table_name
}

output "sqs_queue_url" {
  description = "Work queue URL."
  value       = module.serverless_app.sqs_queue_url
}

output "github_deploy_role_arn" {
  description = "Set as GitHub variable AWS_DEPLOY_ROLE_ARN_PROD. Null when create_foundation = false (single-account: reuse the dev-created role ARN)."
  value       = var.create_foundation ? module.foundation[0].github_deploy_role_arn : null
}

output "alerts_topic_arn" {
  description = "SNS alerts topic. Null when create_foundation = false."
  value       = var.create_foundation ? module.foundation[0].alerts_topic_arn : null
}
