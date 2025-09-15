module "dockersetup" {
  source = "./private_repo"

  name        = "dockersetup"
  description = "Docker stacks to run all lmserver software"
}

resource "github_actions_secret" "dockersetup_cloudflare_client_id" {
  repository      = module.dockersetup.repo_name
  secret_name     = "CLOUDFLARE_CLIENT_ID"
  plaintext_value = data.terraform_remote_state.tf_cloudflare.outputs.github_actions_client_id
}

resource "github_actions_secret" "dockersetup_cloudflare_client_secret" {
  repository      = module.dockersetup.repo_name
  secret_name     = "CLOUDFLARE_CLIENT_SECRET"
  plaintext_value = data.terraform_remote_state.tf_cloudflare.outputs.github_actions_client_secret
}
