terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project
      Env       = var.env
      ManagedBy = "terraform"
    }
  }
}

module "foundation" {
  # Single-account setup: foundation already exists from the dev env
  # (create_foundation = false here by default). In a multi-account Phase 3
  # setup each workload account would create its own foundation.
  count = var.create_foundation ? 1 : 0

  source = "../../modules/foundation"

  project              = var.project
  env                  = var.env
  alert_email          = var.alert_email
  github_repo          = var.github_repo
  state_bucket_arn     = local.state_bucket_arn
  state_lock_table_arn = local.state_lock_table_arn
}

module "serverless_app" {
  source = "../../modules/serverless-app"

  project              = var.project
  env                  = var.env
  enable_pitr          = var.enable_pitr
  cors_allowed_origins = var.cors_allowed_origins
}
