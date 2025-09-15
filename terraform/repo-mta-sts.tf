module "mta_sts" {
  source = "./public_repo"

  name        = "mta-sts"
  description = "This repository contains my MTA-STS configuration"
  
  force_push_bypassers = [ data.github_user.melvyn.node_id ]
}

resource "github_actions_secret" "mta_sts_cloudflare_account_id" {
  repository      = module.mta_sts.repo_name
  secret_name     = "CLOUDFLARE_ACCOUNT_ID"
  plaintext_value = local.cloudflare_account_id
}

resource "github_actions_secret" "mta_sts_cloudflare_api_token" {
  repository      = module.mta_sts.repo_name
  secret_name     = "CLOUDFLARE_API_TOKEN"
  plaintext_value = data.terraform_remote_state.tf_cloudflare.outputs.api_token_mta_sts
}
