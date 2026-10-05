# CloudWatch log groups with bounded retention (14 days) — unbounded log
# retention is a documented free-tier cost trap (docs/architecture.md §2.4).
# Billing alarms live in the foundation module, not here.

resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/lambda/${local.name_prefix}-api"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "worker" {
  name              = "/aws/lambda/${local.name_prefix}-worker"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "api_access" {
  name              = "/aws/apigateway/${local.name_prefix}-api-access"
  retention_in_days = var.log_retention_days
}
