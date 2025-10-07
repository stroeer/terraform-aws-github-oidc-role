# Terraform AWS GitHub OIDC Role

![CI](https://github.com/stroeer/terraform-aws-github-oidc-role/workflows/static%20checks/badge.svg) [![Terraform Registry](https://img.shields.io/badge/Terraform%20Registry-0.0.1-blue.svg)](https://registry.terraform.io/modules/stroeer/github-oidc-role/aws/0.0.1) ![Terraform Version](https://img.shields.io/badge/Terraform-1.5.7+-green.svg)

A Terraform module that creates an AWS IAM role for secure, keyless authentication from GitHub Actions using [OpenID Connect (OIDC)](https://docs.github.com/en/actions/concepts/security/openid-connect). This eliminates the need to store long-lived AWS credentials in GitHub secrets.

## Features

- 🔐 **Secure Authentication**: Uses GitHub's OIDC provider for temporary credentials
- 🎯 **Granular Permissions**: Supports S3 and ECR access with specific resource restrictions
- 🔒 **Branch Protection**: Restricts access to specific GitHub branches/refs
- 📦 **Flexible Configuration**: Optional S3 bucket access and ECR repository permissions

## Prerequisites

Before using this module, you must add the GitHub OIDC identity provider to your AWS account. This is a one-time setup per AWS account.

### Adding GitHub OIDC Provider

You can add the provider via Terraform or AWS CLI:

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com
```

Or follow the [official GitHub documentation](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-aws#adding-the-identity-provider-to-aws).

## Usage

### Example

see [complete example](./examples/complete) for more details

```terraform
resource "aws_iam_openid_connect_provider" "github" {
  client_id_list = ["sts.amazonaws.com"]
  url            = "https://token.actions.githubusercontent.com"
}

module "oidc_role" {
  source     = "registry.terraform.io/stroeer/github-oidc-role/aws"
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
```

## GitHub Actions Integration

Once the role is created, use it in your GitHub Actions workflow:

```yaml
name: Deploy to AWS

on:
  push:
    branches: [main]

# Required for OIDC authentication
permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v5

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v5
        with:
          role-to-assume: github-actions-my-app-us-east-1
          role-session-name: GitHubActions-${{ github.run_id }}
          aws-region: us-east-1

      - name: Deploy to S3
        run: |
          aws s3 sync ./dist/ s3://my-deployment-bucket/my-app/

      - name: Push to ECR
        run: |
          aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
          docker build -t my-app .
          docker tag my-app:latest $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
          docker push $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
```

## How do I contribute to this module?

Contributions are very welcome! Check out the [Contribution Guidelines](https://github.com/stroeer/terraform-aws-github-oidc-role/blob/main/CONTRIBUTING.md) for instructions.

## How is this module versioned?

This Module follows the principles of [Semantic Versioning](http://semver.org/). You can find each new release in the [releases page](../../releases).

During initial development, the major version will be 0 (e.g., `0.x.y`), which indicates the code does not yet have a
stable API. Once we hit `1.0.0`, we will make every effort to maintain a backwards compatible API and use the MAJOR,
MINOR, and PATCH versions on each release to indicate any incompatibilities.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.github_actions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_openid_connect_provider.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_openid_connect_provider) | data source |
| [aws_iam_policy_document.ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.github_actions_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ecr_repositories"></a> [ecr\_repositories](#input\_ecr\_repositories) | ECR repository names that the role can push to. If not set, no ECR access will be granted. | `list(string)` | `[]` | no |
| <a name="input_github_refs"></a> [github\_refs](#input\_github\_refs) | Name of the refs (e.g. branches) on which the action will run. Can contain '*' wildcards. | `list(string)` | <pre>[<br/>  "main"<br/>]</pre> | no |
| <a name="input_github_repository"></a> [github\_repository](#input\_github\_repository) | Name of the GitHub repository that will run the action, including repository owner (e.g. moritzzimmer/terraform-aws-lambda) | `string` | n/a | yes |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | Name of the IAM role to create. If not set github-actions-$github\_repository-$region will be used | `string` | `""` | no |
| <a name="input_s3_prefixes"></a> [s3\_prefixes](#input\_s3\_prefixes) | S3 prefixes (bucket name + key) that the role can write/read to/from. E.g. ci-eu-central-1/foo. If not set, no S3 access will be granted. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | The name of the IAM role created |
<!-- END_TF_DOCS -->