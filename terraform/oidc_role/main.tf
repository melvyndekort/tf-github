terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# ---------------------------------------------------------------------------
# Apply role (AdministratorAccess) per repo. Trust-policy shape shared with
# tf-aws's account-bootstrap module (which bootstraps tf-github's own apply
# role) via gha-workflows' oidc-github-trust-policy module -- see that
# module's README for why it lives there. tf-github improvement plan Phase 2
# item 1.
# ---------------------------------------------------------------------------

module "trust" {
  source = "git::https://github.com/melvyndekort/gha-workflows.git//modules/oidc-github-trust-policy?ref=feat/oidc-trust-policy-module"

  for_each = var.repos

  oidc_provider_arn = data.aws_iam_openid_connect_provider.github.arn
  github_org        = var.github_org
  github_owner_id   = var.github_owner_id
  repo_name         = each.key
  repo_id           = each.value
}

resource "aws_iam_role" "github_actions" {
  for_each = var.repos

  name               = "github-actions-${replace(each.key, ".", "-")}"
  path               = "/external/"
  assume_role_policy = module.trust[each.key].apply_assume_role_policy_json
}

resource "aws_iam_role_policy_attachment" "admin" {
  for_each = var.repos

  role       = aws_iam_role.github_actions[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# ---------------------------------------------------------------------------
# PR plan role (opt-in per repo via `pr_plan_role: true` in repositories.yaml)
#
# Purpose: let `terraform plan` run on pull requests without handing a pull
# request an AdministratorAccess role. Two independent conditions guard it:
#
#   sub              - the caller must be a pull_request event in this exact
#                      repository (immutable owner_id/repo_id format).
#   job_workflow_ref - the job must BE the vetted reusable workflow. Steps
#                      defined in the caller repository carry the caller's own
#                      job_workflow_ref, so code added inside a pull request
#                      cannot hold these credentials.
#
# The role is read-only, but ReadOnlyAccess can read secret values (including
# via terraform_remote_state of another account's state). That is accepted
# deliberately: a plan must configure the same providers as an apply, so the
# exposure is controlled by restricting WHICH CODE may assume the role rather
# than by deny-listing reads. Sensitive Terraform outputs are still redacted
# in plan output, so publishing the plan on a public repo stays safe.
# ---------------------------------------------------------------------------

module "trust_plan" {
  source = "git::https://github.com/melvyndekort/gha-workflows.git//modules/oidc-github-trust-policy?ref=feat/oidc-trust-policy-module"

  for_each = var.aws_plan_role_repos

  oidc_provider_arn      = data.aws_iam_openid_connect_provider.github.arn
  github_org             = var.github_org
  github_owner_id        = var.github_owner_id
  repo_name              = each.key
  repo_id                = each.value
  create_apply_document  = false
  create_plan_document   = true
  plan_job_workflow_refs = var.aws_plan_role_job_workflow_refs
}

resource "aws_iam_role" "github_actions_plan" {
  for_each = var.aws_plan_role_repos

  name               = "github-actions-${replace(each.key, ".", "-")}-plan"
  path               = "/external/"
  description        = "Read-only role for terraform plan on pull requests in ${var.github_org}/${each.key}"
  assume_role_policy = module.trust_plan[each.key].plan_assume_role_policy_json
}

resource "aws_iam_role_policy_attachment" "plan_readonly" {
  for_each = var.aws_plan_role_repos

  role       = aws_iam_role.github_actions_plan[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# ReadOnlyAccess grants only kms:Describe*/Get*/List* -- NOT kms:Decrypt. Repos
# whose plan calls `data.aws_kms_secrets` therefore cannot plan without this.
#
# Adding kms:Decrypt to the plan role's identity policy is sufficient and no
# key-policy edit is needed: the `alias/generic` key policy already delegates to
# `arn:aws:iam::<account>:root`, which lets identity policies in the SAME
# account grant access. Verified -- the existing apply role is absent from the
# key policy yet decrypts successfully, and simulate-principal-policy returns
# `allowed` for it. Every KMS-using repo lives in the key's own account, so this
# path covers all of them.
#
# Decrypt is scoped to the one key and to the repo's own encryption-context
# `target`, and only for repos that opt in with `pr_plan_kms_target`. It does
# not widen what the role can mutate: the role stays read-only, and the plan already reads these same secrets during an
# apply. It does mean a PR plan can read that repo's decrypted secrets -- which
# is why the trust policy pins `job_workflow_ref` to the shared plan workflow,
# so PR-authored code never holds the credential.
data "aws_iam_policy_document" "plan_kms_decrypt" {
  for_each = var.aws_plan_role_kms_key_arns

  statement {
    sid       = "DecryptPlanSecrets"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [each.value]

    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:target"
      values   = [var.aws_plan_role_kms_targets[each.key]]
    }
  }
}

resource "aws_iam_role_policy" "plan_kms_decrypt" {
  for_each = var.aws_plan_role_kms_key_arns

  name   = "kms-decrypt"
  role   = aws_iam_role.github_actions_plan[each.key].name
  policy = data.aws_iam_policy_document.plan_kms_decrypt[each.key].json
}
