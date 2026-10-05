output "alerts_topic_arn" {
  description = "SNS topic ARN receiving budget / anomaly alerts."
  value       = aws_sns_topic.alerts.arn
}

output "github_deploy_role_arn" {
  description = "ARN of the OIDC deploy role. Set it as the GitHub variable AWS_DEPLOY_ROLE_ARN_DEV (and _PROD if the same account)."
  value       = aws_iam_role.github_deploy.arn
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider."
  value       = aws_iam_openid_connect_provider.github.arn
}

output "cloudtrail_bucket_name" {
  description = "S3 bucket receiving CloudTrail logs."
  value       = aws_s3_bucket.cloudtrail.bucket
}
