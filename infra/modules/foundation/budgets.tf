# Cost guardrails (docs/architecture.md §2-§3): budgets -> SNS -> email,
# plus Cost Anomaly Detection. These are among the FIRST resources created in
# the account, before any workload exists.

resource "aws_sns_topic" "alerts" {
  name = "${local.name_prefix}-alerts"
}

resource "aws_sns_topic_subscription" "alerts_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# $1 / $5 / $10 monthly budgets, each with an ACTUAL (>100%) and a
# FORECASTED (>=100%) notification so overspend is caught before month-end.
resource "aws_budgets_budget" "monthly" {
  for_each = toset(var.budget_thresholds_usd)

  name         = "${local.name_prefix}-monthly-${each.value}usd"
  budget_type  = "COST"
  limit_amount = each.value
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_sns_topic_arns = [aws_sns_topic.alerts.arn]
  }

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type         = "FORECASTED"
    subscriber_sns_topic_arns = [aws_sns_topic.alerts.arn]
  }
}

resource "aws_ce_anomaly_monitor" "services" {
  name              = "${local.name_prefix}-services"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
}

resource "aws_ce_anomaly_subscription" "alerts" {
  name      = "${local.name_prefix}-anomaly"
  frequency = "DAILY"

  monitor_arn_list = [aws_ce_anomaly_monitor.services.arn]

  subscriber {
    type    = "EMAIL"
    address = var.alert_email
  }

  # Alert on any anomaly with an impact of $1 or more — portfolio-scale traffic
  # should never spike beyond that.
  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      values        = ["1"]
      match_options = ["GREATER_THAN_OR_EQUAL"]
    }
  }
}
