# GitHub OIDC roles for all repositories except tf-github (managed in bootstrap)

# Data source for tf-github role managed in bootstrap
data "aws_iam_role" "tf_github_role" {
  name = "github-actions-tf-github"
}

# tf-github's own PR plan role. tf-github has no aws_account in
# repositories.yaml (its apply role is bootstrapped in tf-aws, not created by
# the oidc_role module), so the normal per-account plan-role machinery can't
# produce one for it. Create it here as a special case, in the management
# account (the default provider), mirroring the oidc_role module's plan-role
# trust: pull_request subject, job_workflow_ref pinned to the shared plan
# workflow, ReadOnlyAccess, plus kms:Decrypt on alias/generic because
# tf-github's plan decrypts target=tf-github secrets (same account, so the
# identity-policy grant suffices - no key-policy change).
data "aws_iam_openid_connect_provider" "github_management" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "tf_github_plan_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github_management.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${local.github_org}@${local.github_owner_id}/tf-github@${local.repo_ids["tf-github"]}:pull_request",
      ]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:job_workflow_ref"
      values   = local.plan_job_workflow_refs
    }
  }
}

resource "aws_iam_role" "tf_github_plan" {
  name               = "github-actions-tf-github-plan"
  path               = "/external/"
  description        = "Read-only role for terraform plan on pull requests in melvyndekort/tf-github"
  assume_role_policy = data.aws_iam_policy_document.tf_github_plan_assume.json
}

resource "aws_iam_role_policy_attachment" "tf_github_plan_readonly" {
  role       = aws_iam_role.tf_github_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

data "aws_iam_policy_document" "tf_github_plan_kms_decrypt" {
  statement {
    sid       = "DecryptPlanSecrets"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [local.generic_kms_key_arn]
  }
}

resource "aws_iam_role_policy" "tf_github_plan_kms_decrypt" {
  name   = "kms-decrypt"
  role   = aws_iam_role.tf_github_plan.name
  policy = data.aws_iam_policy_document.tf_github_plan_kms_decrypt.json
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
      "tf-github" = aws_iam_role.tf_github_plan.arn
    }
  )
}

output "github_actions_role_arns" {
  value = local.all_role_arns
}

output "github_actions_plan_role_arns" {
  value = local.all_plan_role_arns
}
