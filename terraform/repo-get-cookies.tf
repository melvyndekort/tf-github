module "get_cookies" {
  source = "./public_repo"

  name        = "get-cookies"
  description = "A serverless authentication solution which converts JWT tokens to AWS Cloudfront signed cookies"
  
  force_push_bypassers = [ data.github_user.melvyn.node_id ]
}

resource "github_actions_secret" "get_cookies_codecov_token" {
  repository      = module.get_cookies.repo_name
  secret_name     = "CODECOV_TOKEN"
  plaintext_value = local.secrets.codecov.get-cookies-token
}
