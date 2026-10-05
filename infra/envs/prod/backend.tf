terraform {
  # Partial backend config — same bootstrap variables as dev, different key.
  # See infra/README.md.
  backend "s3" {
    key = "prod/terraform.tfstate"
  }
}
