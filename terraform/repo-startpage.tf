module "startpage" {
  source = "./private_repo"

  name        = "startpage"
  description = "Public website"
}

resource "github_actions_secret" "startpage_cloudflare_account_id" {
  repository      = module.startpage.repo_name
  secret_name     = "CLOUDFLARE_ACCOUNT_ID"
  plaintext_value = local.cloudflare_account_id
}

resource "github_actions_secret" "startpage_cloudflare_api_token" {
  repository      = module.startpage.repo_name
  secret_name     = "CLOUDFLARE_API_TOKEN"
  plaintext_value = data.terraform_remote_state.tf_cloudflare.outputs.api_token_startpage
}
