resource "aws_iam_openid_connect_provider" "github" {
  client_id_list = ["sts.amazonaws.com"]
  url            = "https://token.actions.githubusercontent.com"
}

module "oidc_role" {
  source     = "../../"
  depends_on = [aws_iam_openid_connect_provider.github]

  github_repository = "stroeer/example"
  role_name         = "github-ci-role"
  github_refs       = ["main", "develop", "release/*"]

  ecr_repositories = [
    "example-repository"
  ]

  s3_prefixes = [
    "example-bucket",
    "other-bucket/example-folder"
  ]
}
