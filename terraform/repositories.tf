locals {
  repositories_config = yamldecode(file("${path.module}/repositories.yaml"))

  # Create normalized repo names for Terraform resources (replace periods and hyphens with underscores)
  repo_names = {
    for name, config in local.repositories_config.repositories :
    name => replace(replace(name, ".", "_"), "-", "_")
  }

  # Separate repos by type
  public_repos = {
    for name, config in local.repositories_config.repositories :
    name => config if config.type == "public"
  }

  private_repos = {
    for name, config in local.repositories_config.repositories :
    name => config if config.type == "private"
  }

  custom_repos = {
    for name, config in local.repositories_config.repositories :
    name => config if config.type == "custom"
  }

  # Flatten secrets for easier processing
  all_secrets = flatten([
    for repo_name, config in local.repositories_config.repositories : [
      for secret in try(config.secrets, []) : {
        repo_name   = repo_name
        secret_name = secret.name
        value_ref   = secret.value_ref
      }
    ]
  ])
}

# Public repositories using the module
module "public_repos" {
  for_each = local.public_repos
  source   = "./public_repo"

  name                   = each.key
  description            = each.value.description
  force_push_bypassers   = [data.github_user.melvyn.node_id]
  allowed_actions_config = try(each.value.allowed_actions_config, [])
}

# Private repositories using the module
module "private_repos" {
  for_each = local.private_repos
  source   = "./private_repo"

  name        = each.key
  description = each.value.description
  deploy_keys = try(each.value.deploy_keys, [])
}

# Custom repositories (like melvyndekort.github.io)
resource "github_repository" "custom_repos" {
  for_each = local.custom_repos

  name        = each.key
  description = each.value.description
  visibility  = try(each.value.visibility, "public")

  has_downloads = false
  has_issues    = try(each.value.has_issues, true)
  has_projects  = false
  has_wiki      = false

  auto_init              = true
  allow_auto_merge       = true
  delete_branch_on_merge = true
  vulnerability_alerts   = true
  archive_on_destroy     = true

  dynamic "pages" {
    for_each = try(each.value.pages, null) != null ? [each.value.pages] : []
    content {
      source {
        branch = pages.value.branch
      }
    }
  }
}

# GitHub Actions permissions for custom repositories
resource "github_actions_repository_permissions" "custom_repos" {
  for_each = local.custom_repos

  repository = github_repository.custom_repos[each.key].name

  allowed_actions = "selected"

  allowed_actions_config {
    github_owned_allowed = true
    verified_allowed     = true
    patterns_allowed     = []
  }
}

# Handle default branch for custom repos with pages
data "github_branch" "custom_repo_branches" {
  for_each = {
    for name, config in local.custom_repos :
    name => config if try(config.default_branch, null) != null
  }

  repository = github_repository.custom_repos[each.key].name
  branch     = each.value.default_branch
}

resource "github_branch_default" "custom_repos" {
  for_each = {
    for name, config in local.custom_repos :
    name => config if try(config.default_branch, null) != null
  }

  repository = github_repository.custom_repos[each.key].name
  branch     = data.github_branch.custom_repo_branches[each.key].branch
}

# GitHub Actions secrets
resource "github_actions_secret" "repo_secrets" {
  for_each = {
    for secret in local.all_secrets :
    "${local.repo_names[secret.repo_name]}_${lower(secret.secret_name)}" => secret
  }

  repository = try(
    module.public_repos[each.value.repo_name].repo_name,
    module.private_repos[each.value.repo_name].repo_name,
    github_repository.custom_repos[each.value.repo_name].name
  )
  secret_name = each.value.secret_name
  plaintext_value = lookup({
    "docker_username"                            = local.docker_username
    "docker_password"                            = local.docker_password
    "cloudflare_account_id"                      = local.cloudflare_account_id
    "tf_cloudflare.api_token_startpage"          = data.terraform_remote_state.tf_cloudflare.outputs.api_token_startpage
    "tf_cloudflare.api_token_ignition"           = data.terraform_remote_state.tf_cloudflare.outputs.api_token_ignition
    "tf_cloudflare.api_token_melvyn_dev"         = data.terraform_remote_state.tf_cloudflare.outputs.api_token_melvyn_dev
    "tf_cloudflare.api_token_mta_sts"            = data.terraform_remote_state.tf_cloudflare.outputs.api_token_mta_sts
    "tf_cloudflare.api_token_cheatsheets"        = data.terraform_remote_state.tf_cloudflare.outputs.api_token_cheatsheets
    "tf_cloudflare.api_token_assets"             = data.terraform_remote_state.tf_cloudflare.outputs.api_token_assets
    "tf_cloudflare.github_actions_client_id"     = data.terraform_remote_state.tf_cloudflare.outputs.github_actions_client_id
    "tf_cloudflare.github_actions_client_secret" = data.terraform_remote_state.tf_cloudflare.outputs.github_actions_client_secret
    "github_actions_homelab_role_arn"            = aws_iam_role.github_actions["homelab"].arn
    "github_actions_ignition_role_arn"           = aws_iam_role.github_actions["ignition"].arn
    "github_actions_aws_ntfy_alerts_role_arn"    = aws_iam_role.github_actions["aws-ntfy-alerts"].arn
    "github_actions_tf_github_role_arn"          = data.aws_iam_role.tf_github_role.arn
    "github_actions_tf_cloudflare_role_arn"      = aws_iam_role.github_actions["tf-cloudflare"].arn
    "github_actions_tf_grafana_role_arn"         = aws_iam_role.github_actions["tf-grafana"].arn
    "github_actions_minecraft_server_role_arn"   = aws_iam_role.github_actions["minecraft-server"].arn
    "github_actions_tf_aws_role_arn"             = aws_iam_role.github_actions["tf-aws"].arn
    "github_actions_tf_backup_role_arn"          = aws_iam_role.github_actions["tf-backup"].arn
    "github_actions_tf_cloudtrail_role_arn"      = aws_iam_role.github_actions["tf-cloudtrail"].arn
    "github_actions_tf_cognito_role_arn"         = aws_iam_role.github_actions["tf-cognito"].arn

    "github_actions_melvyn_dev_role_arn"         = aws_iam_role.github_actions["melvyn-dev"].arn
    "github_actions_assets_role_arn"             = aws_iam_role.github_actions["assets"].arn
    "github_actions_cheatsheets_role_arn"        = aws_iam_role.github_actions["cheatsheets"].arn
    "github_actions_get_cookies_role_arn"        = aws_iam_role.github_actions["get-cookies"].arn
    "github_actions_example_melvyn_dev_role_arn" = aws_iam_role.github_actions["example.melvyn.dev"].arn
    "github_actions_startpage_role_arn"          = aws_iam_role.github_actions["startpage"].arn
    "github_actions_email_infra_role_arn"        = aws_iam_role.github_actions["email-infra"].arn
  }, each.value.value_ref, "")
}
