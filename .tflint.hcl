config {
  call_module_type = "local"
}

# see https://github.com/terraform-linters/tflint-ruleset-terraform/blob/main/docs/configuration.md
plugin "terraform" {
  enabled = true
  preset = "recommended"
}

# see https://github.com/terraform-linters/tflint-ruleset-aws/blob/master/docs/configuration.md
plugin "aws" {
  enabled = true
  version = "0.43.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}