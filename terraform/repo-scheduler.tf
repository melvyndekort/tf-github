module "scheduler" {
  source = "./public_repo"

  name        = "scheduler"
  description = "Run scheduled jobs in Docker and trigger them manually via a web interface"
  
  force_push_bypassers = [ data.github_user.melvyn.node_id ]
}

resource "github_actions_secret" "scheduler_docker_username" {
  repository      = module.scheduler.repo_name
  secret_name     = "DOCKER_USERNAME"
  plaintext_value = local.docker_username
}

resource "github_actions_secret" "scheduler_docker_password" {
  repository      = module.scheduler.repo_name
  secret_name     = "DOCKER_PASSWORD"
  plaintext_value = local.docker_password
}

resource "github_actions_secret" "scheduler_codecov_token" {
  repository      = module.scheduler.repo_name
  secret_name     = "CODECOV_TOKEN"
  plaintext_value = local.secrets.codecov.scheduler-token
}
