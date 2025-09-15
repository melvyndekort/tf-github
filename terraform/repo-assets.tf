module "assets" {
  source = "./public_repo"

  name        = "assets"
  description = "This repository contains my static resources site"
  
  force_push_bypassers = [ data.github_user.melvyn.node_id ]
}

resource "github_actions_secret" "assets_cloudflare_account_id" {
  repository      = module.assets.repo_name
  secret_name     = "CLOUDFLARE_ACCOUNT_ID"
  plaintext_value = local.cloudflare_account_id
}

resource "github_actions_secret" "assets_cloudflare_api_token" {
  repository      = module.assets.repo_name
  secret_name     = "CLOUDFLARE_API_TOKEN"
  plaintext_value = data.terraform_remote_state.tf_cloudflare.outputs.api_token_assets
}
