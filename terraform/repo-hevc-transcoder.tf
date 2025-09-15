module "hevc_transcoder" {
  source = "./public_repo"

  name        = "hevc-transcoder"
  description = "HEVC encode all the MP4 files uploaded to an S3 bucket"
  
  force_push_bypassers = [ data.github_user.melvyn.node_id ]
}

resource "github_actions_secret" "hevc_transcoder_docker_username" {
  repository      = module.hevc_transcoder.repo_name
  secret_name     = "DOCKER_USERNAME"
  plaintext_value = local.docker_username
}

resource "github_actions_secret" "hevc_transcoder_docker_password" {
  repository      = module.hevc_transcoder.repo_name
  secret_name     = "DOCKER_PASSWORD"
  plaintext_value = local.docker_password
}

resource "github_actions_secret" "hevc_transcoder_codecov_token" {
  repository      = module.hevc_transcoder.repo_name
  secret_name     = "CODECOV_TOKEN"
  plaintext_value = local.secrets.codecov.hevc-transcoder-token
}
