# GitHub OIDC roles for all repositories except tf-github (managed in bootstrap)

# Data source for tf-github role managed in bootstrap
data "aws_iam_role" "tf_github_role" {
  name = "github-actions-tf-github"
}

# Same for its read-only plan counterpart, also created in bootstrap to avoid a
# circular dependency (a plan role created here would only exist after an apply).
data "aws_iam_role" "tf_github_plan_role" {
  name = "github-actions-tf-github-plan"
}

# Providers per account
#
# The role assumed cross-account differs by trigger: applies use the admin role,
# pull request plans use the read-only plan role. The default is the admin role,
# so anything that does not set this variable keeps working unchanged; the shared
# plan workflow passes the plan role via TF_VAR_subaccount_role_name.
#
# The value is not a secret (these names are public Terraform) and needs no
# validation for safety: a pull request author may set it to anything, but the
# plan role's IAM policy only permits assuming github-actions-tf-github-plan.
# Verified with simulate-principal-policy: the admin role and AdminRole both
# return implicitDeny. Authorisation is IAM's job, not this variable's.
variable "subaccount_role_name" {
  description = "Cross-account role to assume: the admin role for applies, the read-only plan role for PR plans"
  type        = string
  default     = "github-actions-tf-github"
}

provider "aws" {
  alias  = "account_844347863910"
  region = "eu-west-1"

  assume_role {
    role_arn = "arn:aws:iam::844347863910:role/external/${var.subaccount_role_name}"
  }
}

provider "aws" {
  alias  = "account_520519513359"
  region = "eu-west-1"

  assume_role {
    role_arn = "arn:aws:iam::520519513359:role/external/${var.subaccount_role_name}"
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

  # KMS key that `data.aws_kms_secrets` decrypts at plan time. Same account as
  # every repo that uses it, so an identity-policy grant suffices (the key policy
  # already delegates to the account root).
  generic_kms_key_arn = data.terraform_remote_state.tf_aws.outputs.generic_kms_key_arn

  # Opt-in subset of plan_repos: repos whose plan must also decrypt secrets.
  # ReadOnlyAccess covers kms:Describe*/Get*/List* but NOT kms:Decrypt.
  plan_kms_key_arns_by_account = {
    for account_id, repos in local.plan_repos_by_account :
    account_id => {
      for name, repo_id in repos :
      name => local.generic_kms_key_arn
      if try(local.repositories_config.repositories[name].pr_plan_kms_decrypt, false)
    }
  }
}

# One module instance per account

module "oidc_roles_075673041815" {
  source                 = "./oidc_role"
  github_org             = local.github_org
  github_owner_id        = local.github_owner_id
  repos                  = local.oidc_repos_by_account["075673041815"]
  plan_repos             = local.plan_repos_by_account["075673041815"]
  plan_job_workflow_refs = local.plan_job_workflow_refs
  plan_kms_key_arns      = local.plan_kms_key_arns_by_account["075673041815"]
}

module "oidc_roles_844347863910" {
  source                 = "./oidc_role"
  github_org             = local.github_org
  github_owner_id        = local.github_owner_id
  repos                  = local.oidc_repos_by_account["844347863910"]
  plan_repos             = local.plan_repos_by_account["844347863910"]
  plan_job_workflow_refs = local.plan_job_workflow_refs
  plan_kms_key_arns      = local.plan_kms_key_arns_by_account["844347863910"]

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
  plan_kms_key_arns      = local.plan_kms_key_arns_by_account["520519513359"]

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
    {
      "tf-github" = data.aws_iam_role.tf_github_plan_role.arn
    }
  )
}

output "github_actions_role_arns" {
  value = local.all_role_arns
}

output "github_actions_plan_role_arns" {
  value = local.all_plan_role_arns
}
