# GitHub Actions OIDC deploy identity (ADR-0003): no long-lived AWS keys
# anywhere. GitHub's OIDC token is exchanged for short-lived credentials via
# sts:AssumeRoleWithWebIdentity.

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # Well-known thumbprints for token.actions.githubusercontent.com.
  # AWS now validates the chain itself for this IdP; the list is kept for
  # provider-schema compatibility and is safe to leave as-is.
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
  ]
}

data "aws_iam_policy_document" "github_assume_role" {
  statement {
    sid     = "GitHubActionsAssumeRole"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Restricted to this repository's main branch only — PRs and other
    # branches cannot assume the role.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_deploy" {
  name               = "${local.name_prefix}-github-deploy"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role.json
}

# Deploy policy for Terraform CI.
#
# NOTE: least-privilege here is intentionally iterative. Terraform needs broad
# read/write on the services it manages; the statements below scope by service
# and by the project naming prefix where the service supports resource-level
# scoping. Tighten action/resource lists over time as the stack stabilises —
# see ADR-0003 "consequences".
data "aws_iam_policy_document" "github_deploy" {
  # Terraform state: read/write state objects and acquire locks.
  statement {
    sid    = "TerraformStateAccess"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]

    resources = [
      var.state_bucket_arn,
      "${var.state_bucket_arn}/*",
    ]
  }

  statement {
    sid    = "TerraformStateLocking"
    effect = "Allow"

    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:DescribeTable",
    ]

    resources = [var.state_lock_table_arn]
  }

  # Application services managed by the serverless-app module.
  statement {
    sid    = "ServerlessAppManagement"
    effect = "Allow"

    actions = [
      "lambda:*",
      "apigateway:*",
      "dynamodb:*",
      "sqs:*",
      "sns:*",
      "logs:*",
      "cloudwatch:*",
      "cognito-idp:*",
      "s3:*",
      "cloudfront:*",
      "xray:*",
      "ce:*",
      "budgets:*",
      "cloudtrail:*",
    ]

    # Wildcard resources: several of these services (budgets, ce, cloudfront,
    # apigateway management calls) do not support resource-level scoping for
    # the create/delete APIs Terraform drives. Iteratively tighten per-service.
    resources = ["*"]
  }

  # IAM: Terraform must create/attach the Lambda execution roles. Scoped to
  # roles and policies carrying the project prefix in their name/path.
  statement {
    sid    = "IAMForProjectRoles"
    effect = "Allow"

    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:UpdateRole",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:PassRole",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:PutRolePolicy",
      "iam:GetRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:ListInstanceProfilesForRole",
    ]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.name_prefix}-*",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.name_prefix}-*",
    ]
  }

  statement {
    sid    = "IAMReadOnlyForOIDCProvider"
    effect = "Allow"

    actions = [
      "iam:GetOpenIDConnectProvider",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "github_deploy" {
  name   = "${local.name_prefix}-github-deploy"
  policy = data.aws_iam_policy_document.github_deploy.json
}

resource "aws_iam_role_policy_attachment" "github_deploy" {
  role       = aws_iam_role.github_deploy.name
  policy_arn = aws_iam_policy.github_deploy.arn
}
