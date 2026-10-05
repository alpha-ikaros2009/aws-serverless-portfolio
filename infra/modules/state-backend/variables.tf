variable "bucket_name" {
  description = "Globally unique S3 bucket name for Terraform state. No default on purpose — must be unique across all of AWS."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name must be a valid S3 bucket name (lowercase letters, numbers, dots and hyphens)."
  }
}

variable "table_name" {
  description = "DynamoDB table name used for Terraform state locking."
  type        = string
  default     = "terraform-state-locks"
}

variable "tags" {
  description = "Tags applied to state backend resources (Project/Env/ManagedBy come from the caller)."
  type        = map(string)
  default     = {}
}
