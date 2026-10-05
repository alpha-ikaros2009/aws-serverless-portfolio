terraform {
  # Partial backend config: bucket, region and dynamodb_table are passed at
  # init time (they come from the one-time state-backend bootstrap):
  #
  #   terraform init \
  #     -backend-config="bucket=<state bucket name>" \
  #     -backend-config="region=<aws region>" \
  #     -backend-config="dynamodb_table=<lock table name>"
  #
  # See infra/README.md for the full bootstrap order.
  backend "s3" {
    key = "dev/terraform.tfstate"
  }
}
