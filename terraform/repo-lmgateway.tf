module "lmgateway" {
  source = "./public_repo"

  name        = "lmgateway"
  description = "Tiny bastion EC2 server"
  
  force_push_bypassers = [ data.github_user.melvyn.node_id ]
}

resource "github_actions_secret" "lmgateway_docker_username" {
  repository      = module.lmgateway.repo_name
  secret_name     = "DOCKER_USERNAME"
  plaintext_value = local.docker_username
}

resource "github_actions_secret" "lmgateway_docker_password" {
  repository      = module.lmgateway.repo_name
  secret_name     = "DOCKER_PASSWORD"
  plaintext_value = local.docker_password
}
