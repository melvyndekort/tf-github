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
    role_arn = "arn:aws:iam::844347863910:role/external/github-actions-tf-github"
  }
}

provider "aws" {
  alias  = "account_520519513359"
  region = "eu-west-1"

  assume_role {
    role_arn = "arn:aws:iam::520519513359:role/external/github-actions-tf-github"
  }
}

# Derive OIDC role lists from repositories.yaml
locals {
  github_org      = "melvyndekort"
  github_owner_id = tonumber(data.github_user.melvyn.id)

  # repo name => numeric repo_id, across all repo types
  repo_ids = merge(
    { for k, m in module.public_repos : k => tonumber(m.repo_id) },
    { for k, m in module.private_repos : k => tonumber(m.repo_id) },
    { for k, r in github_repository.custom_repos : k => tonumber(r.repo_id) },
  )

  oidc_repos_by_account = {
    for account_id in distinct([
      for name, config in local.repositories_config.repositories :
      config.aws_account if can(config.aws_account)
    ]) :
    account_id => {
      for name, config in local.repositories_config.repositories :
      name => local.repo_ids[name] if try(config.aws_account, null) == account_id
    }
  }

  # Opt-in subset: repos that additionally get a read-only PR plan role.
  # A repo appears here only with `pr_plan_role: true` in repositories.yaml,
  # so every other repo's plan stays unchanged.
  plan_repos_by_account = {
    for account_id, repos in local.oidc_repos_by_account :
    account_id => {
      for name, repo_id in repos :
      name => repo_id
      if try(local.repositories_config.repositories[name].pr_plan_role, false)
    }
  }

  # The reusable workflows allowed to assume any PR plan role. Pinned to a tag
  # in the shared workflow repo; bumping the tag is a deliberate change here.
  plan_job_workflow_refs = [
    "melvyndekort/gha-workflows/.github/workflows/terraform-pr-plan.yml@*",
  ]
}

# One module instance per account

module "oidc_roles_075673041815" {
  source                 = "./oidc_role"
  github_org             = local.github_org
  github_owner_id        = local.github_owner_id
  repos                  = local.oidc_repos_by_account["075673041815"]
  plan_repos             = local.plan_repos_by_account["075673041815"]
  plan_job_workflow_refs = local.plan_job_workflow_refs
}

module "oidc_roles_844347863910" {
  source                 = "./oidc_role"
  github_org             = local.github_org
  github_owner_id        = local.github_owner_id
  repos                  = local.oidc_repos_by_account["844347863910"]
  plan_repos             = local.plan_repos_by_account["844347863910"]
  plan_job_workflow_refs = local.plan_job_workflow_refs

  providers = {
    aws = aws.account_844347863910
  }
}

module "oidc_roles_520519513359" {
  source                 = "./oidc_role"
  github_org             = local.github_org
  github_owner_id        = local.github_owner_id
  repos                  = local.oidc_repos_by_account["520519513359"]
  plan_repos             = local.plan_repos_by_account["520519513359"]
  plan_job_workflow_refs = local.plan_job_workflow_refs

  providers = {
    aws = aws.account_520519513359
  }
}

locals {
  all_role_arns = merge(
    module.oidc_roles_075673041815.role_arns,
    module.oidc_roles_844347863910.role_arns,
    module.oidc_roles_520519513359.role_arns,
    {
      "tf-github" = data.aws_iam_role.tf_github_role.arn
    }
  )

  all_plan_role_arns = merge(
    module.oidc_roles_075673041815.plan_role_arns,
    module.oidc_roles_844347863910.plan_role_arns,
    module.oidc_roles_520519513359.plan_role_arns,
  )
}

output "github_actions_role_arns" {
  value = local.all_role_arns
}

output "github_actions_plan_role_arns" {
  value = local.all_plan_role_arns
}
