# GitHub OIDC roles for all repositories except tf-github (managed in bootstrap)

# Data source for tf-github role managed in bootstrap
data "aws_iam_role" "tf_github_role" {
  name = "github-actions-tf-github"
}

# Providers per account
provider "aws" {
  alias  = "account_844347863910"
  region = "eu-west-1"

  assume_role {
    role_arn = "arn:aws:iam::844347863910:role/AdminRole"
  }
}

# Derive OIDC role lists from repositories.yaml
locals {
  github_org = "melvyndekort"

  oidc_repos_by_account = {
    for account_id in distinct([
      for name, config in local.repositories_config.repositories :
      config.aws_account if can(config.aws_account)
    ]) :
    account_id => toset([
      for name, config in local.repositories_config.repositories :
      name if try(config.aws_account, null) == account_id
    ])
  }
}

# One module instance per account

module "oidc_roles_075673041815" {
  source     = "./oidc_role"
  github_org = local.github_org
  repos      = local.oidc_repos_by_account["075673041815"]
}

module "oidc_roles_844347863910" {
  source     = "./oidc_role"
  github_org = local.github_org
  repos      = local.oidc_repos_by_account["844347863910"]

  providers = {
    aws = aws.account_844347863910
  }
}

locals {
  all_role_arns = merge(
    module.oidc_roles_075673041815.role_arns,
    module.oidc_roles_844347863910.role_arns,
    {
      "tf-github" = data.aws_iam_role.tf_github_role.arn
    }
  )
}

output "github_actions_role_arns" {
  value = local.all_role_arns
}
