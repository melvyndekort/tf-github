module "ignition" {
  source = "./public_repo"

  name        = "ignition"
  description = "This repository contains my ignition files for Fedora CoreOS"
  
  force_push_bypassers = [ data.github_user.melvyn.node_id ]

  allowed_actions_config = [
    "robinraju/release-downloader@*"
  ]
}

resource "github_actions_secret" "ignition_cloudflare_account_id" {
  repository      = module.ignition.repo_name
  secret_name     = "CLOUDFLARE_ACCOUNT_ID"
  plaintext_value = local.cloudflare_account_id
}

resource "github_actions_secret" "ignition_cloudflare_api_token" {
  repository      = module.ignition.repo_name
  secret_name     = "CLOUDFLARE_API_TOKEN"
  plaintext_value = data.terraform_remote_state.tf_cloudflare.outputs.api_token_ignition
}
