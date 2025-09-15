module "melvyn_dev" {
  source = "./public_repo"

  name        = "melvyn-dev"
  description = "Public website"
  
  force_push_bypassers = [ data.github_user.melvyn.node_id ]
}

resource "github_actions_secret" "melvyn_dev_cloudflare_account_id" {
  repository      = module.melvyn_dev.repo_name
  secret_name     = "CLOUDFLARE_ACCOUNT_ID"
  plaintext_value = local.cloudflare_account_id
}

resource "github_actions_secret" "melvyn_dev_cloudflare_api_token" {
  repository      = module.melvyn_dev.repo_name
  secret_name     = "CLOUDFLARE_API_TOKEN"
  plaintext_value = data.terraform_remote_state.tf_cloudflare.outputs.api_token_melvyn_dev
}
