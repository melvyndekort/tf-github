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

data "aws_iam_policy_document" "assume" {
  for_each = var.repos

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
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
        # Immutable-subject format (embeds owner_id/repo_id), GitHub's
        # current default for newly created repos.
        #
        # Only the `:environment:production` subject is now accepted. This
        # makes the production environment load-bearing: all applies must
        # route through the environment gate. Completes §7.2 of the planning
        # doc (step 4/4: drop the main-branch fallback).
        "repo:${var.github_org}@${var.github_owner_id}/${each.key}@${each.value}:environment:production",
      ]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  for_each = var.repos

  name = "github-actions-${replace(each.key, ".", "-")}"
  path = "/external/"
  # tf-github-redesign-plan-2026-10.md §4.2a: scoped roles (every repo
  # NOT in full_admin_repos) get PowerUserAccess as their boundary,
  # pointed directly at the AWS-managed ARN - no custom policy document
  # to author or keep in sync, so "what a created role can do" and "what
  # the apply role itself can do" cap out at the same policy. Full-admin
  # roles (the escape hatch) get no boundary.
  permissions_boundary = contains(keys(var.full_admin_repos), each.key) ? null : "arn:aws:iam::aws:policy/PowerUserAccess"
  assume_role_policy    = data.aws_iam_policy_document.assume[each.key].json
}

resource "aws_iam_role_policy_attachment" "admin" {
  for_each = var.full_admin_repos

  role       = aws_iam_role.github_actions[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# tf-github-redesign-plan-2026-10.md §4.2a: PowerUserAccess default for
# every repo not in the full_admin_repos escape hatch.
locals {
  scoped_repos = {
    for name, repo_id in var.repos : name => repo_id
    if !contains(keys(var.full_admin_repos), name)
  }
}

resource "aws_iam_role_policy_attachment" "power_user" {
  for_each = local.scoped_repos

  role       = aws_iam_role.github_actions[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# Guardrail deny (§4.2a): a blast-radius ceiling independent of the
# boundary, covering what PowerUserAccess does not itself block -
# org/account/billing operations and tampering with the OIDC trust this
# whole design depends on. Applies only to scoped (non-full-admin) roles;
# a full-admin role already has broader reach than this would deny
# anyway, so attaching it there would be theatre.
data "aws_iam_policy_document" "guardrail_deny" {
  statement {
    sid    = "NoOrgBillingOrAccountOps"
    effect = "Deny"
    actions = [
      "organizations:*",
      "account:*",
      "aws-portal:*",
      "iam:CreateUser",
      "iam:CreateAccessKey",
      "iam:AttachUserPolicy",
      "iam:DeleteAccountPasswordPolicy",
      "iam:UpdateAccountPasswordPolicy",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "NoTamperingWithOIDCTrust"
    effect    = "Deny"
    actions   = ["iam:DeleteOpenIDConnectProvider", "iam:UpdateOpenIDConnectProviderThumbprint", "cloudtrail:StopLogging", "cloudtrail:DeleteTrail"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "guardrail_deny" {
  for_each = local.scoped_repos

  name   = "guardrail-deny"
  role   = aws_iam_role.github_actions[each.key].name
  policy = data.aws_iam_policy_document.guardrail_deny.json
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

data "aws_iam_policy_document" "assume_plan" {
  for_each = var.plan_repos

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
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
        "repo:${var.github_org}@${var.github_owner_id}/${each.key}@${each.value}:pull_request",
      ]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:job_workflow_ref"
      values   = var.plan_job_workflow_refs
    }
  }
}

resource "aws_iam_role" "github_actions_plan" {
  for_each = var.plan_repos

  name               = "github-actions-${replace(each.key, ".", "-")}-plan"
  path               = "/external/"
  description        = "Read-only role for terraform plan on pull requests in ${var.github_org}/${each.key}"
  assume_role_policy = data.aws_iam_policy_document.assume_plan[each.key].json
}

resource "aws_iam_role_policy_attachment" "plan_readonly" {
  for_each = var.plan_repos

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
  for_each = var.plan_kms_key_arns

  statement {
    sid       = "DecryptPlanSecrets"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [each.value]

    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:target"
      values   = [var.plan_kms_targets[each.key]]
    }
  }
}

resource "aws_iam_role_policy" "plan_kms_decrypt" {
  for_each = var.plan_kms_key_arns

  name   = "kms-decrypt"
  role   = aws_iam_role.github_actions_plan[each.key].name
  policy = data.aws_iam_policy_document.plan_kms_decrypt[each.key].json
}
