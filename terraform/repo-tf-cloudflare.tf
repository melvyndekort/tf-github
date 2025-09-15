module "tf_cloudflare" {
  source = "./public_repo"

  name        = "tf-cloudflare"
  description = "Centrally manage cloudflare configuration"
  
  force_push_bypassers = [ data.github_user.melvyn.node_id ]
}

resource "github_actions_secret" "tf_cloudflare_role_arn" {
  repository      = module.tf_cloudflare.repo_name
  secret_name     = "AWS_ROLE_ARN"
  plaintext_value = "arn:aws:iam::075673041815:role/external/github-actions-tf-cloudflare"
}

