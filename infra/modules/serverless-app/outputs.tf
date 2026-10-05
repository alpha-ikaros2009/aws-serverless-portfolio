output "site_bucket_name" {
  description = "S3 bucket holding the static site (deploy workflow syncs web/ here)."
  value       = aws_s3_bucket.site.bucket
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (used for cache invalidation after deploys)."
  value       = aws_cloudfront_distribution.site.id
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name — the public URL of the site in Phase 1."
  value       = aws_cloudfront_distribution.site.domain_name
}

output "api_endpoint" {
  description = "API Gateway HTTP API invoke URL (the $default stage has no path suffix)."
  value       = aws_apigatewayv2_api.api.api_endpoint
}

output "cognito_user_pool_id" {
  description = "Cognito user pool ID (frontend auth config)."
  value       = aws_cognito_user_pool.main.id
}

output "cognito_user_pool_client_id" {
  description = "Cognito SPA app client ID (frontend auth config)."
  value       = aws_cognito_user_pool_client.spa.id
}

output "cognito_issuer_url" {
  description = "Cognito issuer URL used by the JWT authorizer."
  value       = "https://${aws_cognito_user_pool.main.endpoint}"
}

output "dynamodb_table_name" {
  description = "Single-table DynamoDB table name."
  value       = aws_dynamodb_table.main.name
}

output "sqs_queue_url" {
  description = "Work queue URL (also injected into the api Lambda env)."
  value       = aws_sqs_queue.work.url
}

output "api_lambda_name" {
  description = "api Lambda function name."
  value       = aws_lambda_function.api.function_name
}

output "worker_lambda_name" {
  description = "worker Lambda function name."
  value       = aws_lambda_function.worker.function_name
}
