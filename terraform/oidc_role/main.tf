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
        "repo:${var.github_org}@${var.github_owner_id}/${each.key}@${each.value}:ref:refs/heads/main",
      ]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  for_each = var.repos

  name               = "github-actions-${replace(each.key, ".", "-")}"
  path               = "/external/"
  assume_role_policy = data.aws_iam_policy_document.assume[each.key].json
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
