locals {
  role_name           = var.role_name != "" ? var.role_name : "github-actions-${split("/", var.github_repository)[1]}-${data.aws_region.current.region}"
  allowed_subs        = [for ref in var.github_refs : "repo:${var.github_repository}:ref/refs/heads/${ref}"]
  s3_bucket_name_arns = [for prefix in var.s3_prefixes : "arn:aws:s3:::${split("/", prefix)[0]}"]
  s3_prefix_arns      = [for prefix in var.s3_prefixes : "arn:aws:s3:::${prefix}/*"]
  ecr_repository_arns = [for repo in var.ecr_repositories : "arn:aws:ecr:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:repository/${repo}"]
}

resource "aws_iam_role" "github_actions" {
  name               = local.role_name
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume.json
}

data "aws_iam_policy_document" "github_actions_assume" {
  statement {
    sid     = "GithubOIDCAccess"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      values   = local.allowed_subs
      variable = "token.actions.githubusercontent.com:sub"
    }

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.id]
    }
  }
}

resource "aws_iam_role_policy" "s3" {
  count  = length(var.s3_prefixes) > 0 ? 1 : 0
  role   = aws_iam_role.github_actions.name
  name   = "s3-access"
  policy = data.aws_iam_policy_document.s3[0].json
}

data "aws_iam_policy_document" "s3" {
  count = length(var.s3_prefixes) > 0 ? 1 : 0
  statement {
    sid       = "BucketLevelAccess"
    effect    = "Allow"
    resources = local.s3_bucket_name_arns
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket"
    ]
  }

  statement {
    sid       = "ObjectLevelAccess"
    effect    = "Allow"
    resources = local.s3_prefix_arns
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject"
    ]
  }
}

resource "aws_iam_role_policy" "ecr" {
  count  = length(var.ecr_repositories) > 0 ? 1 : 0
  role   = aws_iam_role.github_actions.name
  name   = "ecr-access"
  policy = data.aws_iam_policy_document.ecr[0].json
}

data "aws_iam_policy_document" "ecr" {
  count = length(var.ecr_repositories) > 0 ? 1 : 0
  statement {
    sid       = "GetAuthToken"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "PutImage"
    effect = "Allow"
    actions = [
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]
    resources = local.ecr_repository_arns
  }
}
