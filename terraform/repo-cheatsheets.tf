module "cheatsheets" {
  source = "./public_repo"

  name        = "cheatsheets"
  description = "Documentation used in my custom Arch setup"
  
  force_push_bypassers = [ data.github_user.melvyn.node_id ]
}

resource "github_actions_secret" "cheatsheets_cloudflare_account_id" {
  repository      = module.cheatsheets.repo_name
  secret_name     = "CLOUDFLARE_ACCOUNT_ID"
  plaintext_value = local.cloudflare_account_id
}

resource "github_actions_secret" "cheatsheets_cloudflare_api_token" {
  repository      = module.cheatsheets.repo_name
  secret_name     = "CLOUDFLARE_API_TOKEN"
  plaintext_value = data.terraform_remote_state.tf_cloudflare.outputs.api_token_cheatsheets
}
