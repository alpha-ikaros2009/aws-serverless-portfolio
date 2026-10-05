data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  name_prefix = "${var.project}-${var.env}"

  # ARNs of the state backend, derived from names so the foundation module can
  # grant the CI deploy role state access without a data lookup dependency.
  state_bucket_arn     = "arn:aws:s3:::${var.state_bucket_name}"
  state_lock_table_arn = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.state_lock_table_name}"
}
