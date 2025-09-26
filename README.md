# Terraform AWS GitHub OIDC Role

A Terraform module that creates an AWS IAM role for secure, keyless authentication from GitHub Actions using [OpenID Connect (OIDC)](https://docs.github.com/en/actions/concepts/security/openid-connect). This eliminates the need to store long-lived AWS credentials in GitHub secrets.

## Features

- 🔐 **Secure Authentication**: Uses GitHub's OIDC provider for temporary credentials
- 🎯 **Granular Permissions**: Supports S3 and ECR access with specific resource restrictions
- 🔒 **Branch Protection**: Restricts access to specific GitHub branches/refs
- 📦 **Flexible Configuration**: Optional S3 bucket access and ECR repository permissions

## Prerequisites

Before using this module, you must add the GitHub OIDC identity provider to your AWS account. This is a one-time setup per AWS account.

### Adding GitHub OIDC Provider

You can add the provider via AWS CLI:

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com
```

Or follow the [official GitHub documentation](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-aws#adding-the-identity-provider-to-aws).

## Usage

### Basic Example

```terraform
module "github_oidc_role" {
  source = "registry.terraform.io/stroeer/github-oidc-role/aws"

  github_repository = "myorg/my-app"
  
  # Grant access to S3 buckets/prefixes
  s3_prefixes = [
    "my-deployment-bucket/my-app",
    "shared-assets-bucket/static-files"
  ]
  
  # Grant access to ECR repositories
  ecr_repositories = [
    "my-app",
    "my-app-nginx"
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
