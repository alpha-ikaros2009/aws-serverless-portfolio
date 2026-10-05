data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  name_prefix = "${var.project}-${var.env}"

  # AWS managed CloudFront cache / origin-request policy IDs (stable,
  # account-independent). See "Managed policies" in the CloudFront docs.
  cloudfront_caching_optimized_policy_id          = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  cloudfront_caching_disabled_policy_id           = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
  cloudfront_all_viewer_except_host_header_policy = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
}
