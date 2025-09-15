module "image_refresher" {
  source = "./public_repo"

  name        = "image-refresher"
  description = "Docker container which updates specified docker images on the local system"
  
  force_push_bypassers = [ data.github_user.melvyn.node_id ]
}

resource "github_actions_secret" "image_refresher_docker_username" {
  repository      = module.image_refresher.repo_name
  secret_name     = "DOCKER_USERNAME"
  plaintext_value = local.docker_username
}

resource "github_actions_secret" "image_refresher_docker_password" {
  repository      = module.image_refresher.repo_name
  secret_name     = "DOCKER_PASSWORD"
  plaintext_value = local.docker_password
}

resource "github_actions_secret" "image_refresher_codecov_token" {
  repository      = module.image_refresher.repo_name
  secret_name     = "CODECOV_TOKEN"
  plaintext_value = local.secrets.codecov.image-refresher-token
}
