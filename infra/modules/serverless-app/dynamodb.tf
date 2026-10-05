# DynamoDB single-table design (ADR-0002): one table, on-demand billing,
# generic PK/SK + one GSI. Access patterns are documented at the top of
# services/api/handler.py.

resource "aws_dynamodb_table" "main" {
  name         = "${local.name_prefix}-main"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  attribute {
    name = "GSI1PK"
    type = "S"
  }

  attribute {
    name = "GSI1SK"
    type = "S"
  }

  global_secondary_index {
    name            = "GSI1"
    hash_key        = "GSI1PK"
    range_key       = "GSI1SK"
    projection_type = "ALL"
  }

  # SSE with the AWS-owned key (default when no kms_key_arn is given) —
  # free; a customer-managed CMK is a Phase 3 upgrade ($1/key/month).
  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = var.enable_pitr
  }
}
