# Lambda: python3.13 on arm64 (Graviton — ~20% better price/performance,
# docs/architecture.md §5). Deployment packages are zipped from source dirs by
# the archive_file data source, so CI does not need a separate build step.

data "archive_file" "api" {
  type        = "zip"
  source_dir  = var.api_source_dir
  output_path = "${path.module}/.build/api.zip"
  excludes    = ["test_handler.py", "__pycache__"]
}

data "archive_file" "worker" {
  type        = "zip"
  source_dir  = var.worker_source_dir
  output_path = "${path.module}/.build/worker.zip"
  excludes    = ["test_handler.py", "__pycache__"]
}

resource "aws_lambda_function" "api" {
  function_name    = "${local.name_prefix}-api"
  role             = aws_iam_role.api.arn
  runtime          = "python3.13"
  architectures    = ["arm64"]
  handler          = "handler.handler"
  memory_size      = var.lambda_memory_size
  timeout          = var.lambda_timeout
  filename         = data.archive_file.api.output_path
  source_code_hash = data.archive_file.api.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.main.name
      QUEUE_URL  = aws_sqs_queue.work.url
    }
  }

  tracing_config {
    mode = "Active"
  }

  depends_on = [aws_cloudwatch_log_group.api]
}

resource "aws_lambda_function" "worker" {
  function_name    = "${local.name_prefix}-worker"
  role             = aws_iam_role.worker.arn
  runtime          = "python3.13"
  architectures    = ["arm64"]
  handler          = "handler.handler"
  memory_size      = var.lambda_memory_size
  timeout          = var.lambda_timeout
  filename         = data.archive_file.worker.output_path
  source_code_hash = data.archive_file.worker.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.main.name
    }
  }

  tracing_config {
    mode = "Active"
  }

  depends_on = [aws_cloudwatch_log_group.worker]
}

# SQS -> worker Lambda with partial-batch failure reporting: the handler
# returns per-message failures so only failed records are retried/redriven.
resource "aws_lambda_event_source_mapping" "worker" {
  event_source_arn = aws_sqs_queue.work.arn
  function_name    = aws_lambda_function.worker.arn
  batch_size       = 10

  function_response_types = ["ReportBatchItemFailures"]
}
