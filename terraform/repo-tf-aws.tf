module "tf_aws" {
  source = "./public_repo"

  name        = "tf-aws"
  description = "Manage centralized AWS resources using Terraform"
  
  force_push_bypassers = [ data.github_user.melvyn.node_id ]
}

resource "github_actions_secret" "tf_aws_role_arn" {
  repository      = module.tf_aws.repo_name
  secret_name     = "AWS_ROLE_ARN"
  plaintext_value = "arn:aws:iam::075673041815:role/external/github-actions-tf-aws"
}

