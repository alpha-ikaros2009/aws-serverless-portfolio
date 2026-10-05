output "bucket_name" {
  description = "Name of the Terraform state bucket. Use it in `terraform init -backend-config=\"bucket=...\"`."
  value       = aws_s3_bucket.state.bucket
}

output "bucket_arn" {
  description = "ARN of the Terraform state bucket (granted to the CI deploy role by the foundation module)."
  value       = aws_s3_bucket.state.arn
}

output "lock_table_name" {
  description = "Name of the DynamoDB state lock table. Use it in `terraform init -backend-config=\"dynamodb_table=...\"`."
  value       = aws_dynamodb_table.locks.name
}

output "lock_table_arn" {
  description = "ARN of the DynamoDB state lock table."
  value       = aws_dynamodb_table.locks.arn
}
