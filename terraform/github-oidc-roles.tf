# GitHub OIDC roles for all repositories except tf-github (managed in bootstrap)

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# Data source for tf-github role managed in bootstrap
data "aws_iam_role" "tf_github_role" {
  name = "github-actions-tf-github"
}

locals {
  github_repos = {
    "assets" = {
      repo_name = "melvyndekort/assets"
      role_name = "github-actions-assets"
    }
    "aws-ntfy-alerts" = {
      repo_name = "melvyndekort/aws-ntfy-alerts"
      role_name = "github-actions-aws-ntfy-alerts"
    }
    "cheatsheets" = {
      repo_name = "melvyndekort/cheatsheets"
      role_name = "github-actions-cheatsheets"
    }
    "lmserver" = {
      repo_name = "melvyndekort/lmserver"
      role_name = "github-actions-lmserver"
    }
    "ignition" = {
      repo_name = "melvyndekort/ignition"
      role_name = "github-actions-ignition"
    }

    "melvyn-dev" = {
      repo_name = "melvyndekort/melvyn-dev"
      role_name = "github-actions-melvyn-dev"
    }
    "mta-sts" = {
      repo_name = "melvyndekort/mta-sts"
      role_name = "github-actions-mta-sts"
    }
    "tf-aws" = {
      repo_name = "melvyndekort/tf-aws"
      role_name = "github-actions-tf-aws"
    }
    "tf-cloudflare" = {
      repo_name = "melvyndekort/tf-cloudflare"
      role_name = "github-actions-tf-cloudflare"
    }
    "tf-grafana" = {
      repo_name = "melvyndekort/tf-grafana"
      role_name = "github-actions-tf-grafana"
    }
    "tf-backup" = {
      repo_name = "melvyndekort/tf-backup"
      role_name = "github-actions-tf-backup"
    }
    "tf-minecraft" = {
      repo_name = "melvyndekort/tf-minecraft"
      role_name = "github-actions-tf-minecraft"
    }
    "get-cookies" = {
      repo_name = "melvyndekort/get-cookies"
      role_name = "github-actions-get-cookies"
    }
    "example.melvyn.dev" = {
      repo_name = "melvyndekort/example.melvyn.dev"
      role_name = "github-actions-example-melvyn-dev"
    }
    "startpage" = {
      repo_name = "melvyndekort/startpage"
      role_name = "github-actions-startpage"
    }
    "email-infra" = {
      repo_name = "melvyndekort/email-infra"
      role_name = "github-actions-email-infra"
    }
  }
}

data "aws_iam_policy_document" "github_actions_assume" {
  for_each = local.github_repos

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
      values   = ["repo:${each.value.repo_name}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  for_each = local.github_repos

  name               = each.value.role_name
  path               = "/external/"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume[each.key].json
}

resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  for_each = local.github_repos

  role       = aws_iam_role.github_actions[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "github_actions_role_arns" {
  value = merge(
    {
      for k, v in aws_iam_role.github_actions : k => v.arn
    },
    {
      "tf-github" = data.aws_iam_role.tf_github_role.arn
    }
  )
}
