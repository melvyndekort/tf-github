module "mdekort_nl" {
  source = "./public_repo"

  name        = "mdekort-nl"
  description = "Public website"
  
  force_push_bypassers = [ data.github_user.melvyn.node_id ]
}

resource "github_actions_secret" "mdekort_nl_cloudflare_account_id" {
  repository      = module.mdekort_nl.repo_name
  secret_name     = "CLOUDFLARE_ACCOUNT_ID"
  plaintext_value = local.cloudflare_account_id
}

resource "github_actions_secret" "mdekort_nl_cloudflare_api_token" {
  repository      = module.mdekort_nl.repo_name
  secret_name     = "CLOUDFLARE_API_TOKEN"
  plaintext_value = data.terraform_remote_state.tf_cloudflare.outputs.api_token_mdekort_nl
}
