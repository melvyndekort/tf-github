data "github_user" "melvyn" {
  username = "melvyndekort"
}

locals {
  docker_username       = "melvyndekort"
  docker_password       = local.secrets.github.docker_password
  cloudflare_account_id = local.secrets.cloudflare.account_id
}
