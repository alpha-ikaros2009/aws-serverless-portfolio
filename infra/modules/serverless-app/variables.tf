variable "project" {
  description = "Project slug used in resource naming (e.g. \"portfolio\")."
  type        = string
}

variable "env" {
  description = "Environment name (dev / prod)."
  type        = string
}

variable "enable_pitr" {
  description = "Enable DynamoDB point-in-time recovery. Off in dev (free-tier posture), on in prod (docs/architecture.md §5)."
  type        = bool
  default     = false
}

variable "lambda_memory_size" {
  description = "Lambda memory in MB. 128 MB keeps both functions deep inside the Always Free 400,000 GB-seconds."
  type        = number
  default     = 128
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds."
  type        = number
  default     = 10
}

variable "log_retention_days" {
  description = "CloudWatch log retention. Unbounded retention is a classic cost trap (docs/architecture.md §2.4)."
  type        = number
  default     = 14
}

variable "cors_allowed_origins" {
  description = "Allowed CORS origins for the HTTP API. Tighten to the CloudFront/custom domain in Phase 2."
  type        = list(string)
  default     = ["*"]
}

variable "api_source_dir" {
  description = "Path to the api Lambda source directory, relative to the root module the env is applied from."
  type        = string
  default     = "../../../services/api"
}

variable "worker_source_dir" {
  description = "Path to the worker Lambda source directory, relative to the root module the env is applied from."
  type        = string
  default     = "../../../services/worker"
}

# Phase 2 placeholder (docs/architecture.md §5): custom domain + ACM.
# The distribution currently uses the default *.cloudfront.net certificate;
# uncomment and wire aliases/viewer_certificate when a Route 53 zone exists.
#
# variable "domain_name" {
#   description = "Custom domain for the CloudFront distribution (Phase 2)."
#   type        = string
#   default     = null
# }
#
# variable "acm_certificate_arn" {
#   description = "ACM certificate ARN in us-east-1 for the custom domain (Phase 2)."
#   type        = string
#   default     = null
# }
