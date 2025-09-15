module "tf_github" {
  source = "./public_repo"

  name        = "tf-github"
  description = "Centrally manage github configuration"
  
  force_push_bypassers = [ data.github_user.melvyn.node_id ]
}

resource "github_actions_secret" "tf_github_role_arn" {
  repository      = module.tf_github.repo_name
  secret_name     = "AWS_ROLE_ARN"
  plaintext_value = "arn:aws:iam::075673041815:role/external/github-actions-tf-github"
}

