# SQS: async work queue for the api Lambda, consumed by the worker Lambda,
# with a DLQ after 3 failed receives.

resource "aws_sqs_queue" "work_dlq" {
  name = "${local.name_prefix}-work-dlq"

  # Keep failed messages long enough to inspect during debugging.
  message_retention_seconds = 1209600
}

resource "aws_sqs_queue" "work" {
  name = "${local.name_prefix}-work"

  # Must be at least 6x the consumer Lambda timeout so a running invocation
  # is never handed to a second poller.
  visibility_timeout_seconds = var.lambda_timeout * 6

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.work_dlq.arn
    maxReceiveCount     = 3
  })
}
