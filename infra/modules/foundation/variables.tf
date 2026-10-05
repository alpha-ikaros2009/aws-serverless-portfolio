variable "project" {
  description = "Project slug used in resource naming (e.g. \"portfolio\")."
  type        = string
}

variable "env" {
  description = "Environment name (dev / prod). Foundation is account-level; typically only created once per account."
  type        = string
}

variable "alert_email" {
  description = "Email address receiving budget / anomaly / alarm notifications. Subscription must be confirmed once by clicking the SNS confirmation email."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository in \"owner/repo\" form. The OIDC deploy role trust policy is restricted to this repo's main branch."
  type        = string
}

variable "state_bucket_arn" {
  description = "ARN of the Terraform state S3 bucket (from the state-backend module), granted to the deploy role."
  type        = string
}

variable "state_lock_table_arn" {
  description = "ARN of the Terraform state lock DynamoDB table, granted to the deploy role."
  type        = string
}

variable "budget_thresholds_usd" {
  description = "Monthly budget alarm thresholds in USD. First two AWS Budgets are free; keep this list short."
  type        = list(string)
  default     = ["1", "5", "10"]
}
