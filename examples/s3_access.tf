module "s3_oidc_role" {
  source  = "registry.terraform.io/stroeer/github-oidc-role/aws"
  version = "1.0.0"

  github_repository = "stroeer/example"
  s3_prefixes = [
    "example-bucket",
    "other-bucket/example-folder"
  ]

  # Optional
  role_name   = "github-ci-role"
  github_refs = ["main", "develop"]
}
