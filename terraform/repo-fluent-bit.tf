module "fluent_bit" {
  source = "./public_repo"

  name        = "fluent-bit"
  description = "Fluent Bit is a Fast and Lightweight Log Processor and Forwarder for Linux, OSX and BSD family operating systems"
  
  force_push_bypassers = [ data.github_user.melvyn.node_id ]
}

resource "github_actions_secret" "fluent_bit_docker_username" {
  repository      = module.fluent_bit.repo_name
  secret_name     = "DOCKER_USERNAME"
  plaintext_value = local.docker_username
}

resource "github_actions_secret" "fluent_bit_docker_password" {
  repository      = module.fluent_bit.repo_name
  secret_name     = "DOCKER_PASSWORD"
  plaintext_value = local.docker_password
}
