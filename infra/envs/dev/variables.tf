variable "project" {
  description = "Project slug used in all resource names."
  type        = string
  default     = "portfolio"
}

variable "env" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region for this environment."
  type        = string
  default     = "ap-northeast-1"
}

variable "alert_email" {
  description = "Email receiving budget / anomaly alerts (only used when create_foundation = true)."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository in \"owner/repo\" form; the OIDC deploy role is restricted to its main branch."
  type        = string
}

variable "state_bucket_name" {
  description = "Name of the Terraform state bucket created by the one-time state-backend bootstrap."
  type        = string
}

variable "state_lock_table_name" {
  description = "Name of the Terraform state lock table created by the one-time state-backend bootstrap."
  type        = string
  default     = "terraform-state-locks"
}

variable "create_foundation" {
  description = "Create account-level foundation resources. True in exactly one env per account (dev), false elsewhere."
  type        = bool
  default     = true
}

variable "enable_pitr" {
  description = "Enable DynamoDB point-in-time recovery for the app table."
  type        = bool
  default     = false
}

variable "cors_allowed_origins" {
  description = "Allowed CORS origins for the HTTP API. Tighten once the CloudFront domain is known."
  type        = list(string)
  default     = ["*"]
}
