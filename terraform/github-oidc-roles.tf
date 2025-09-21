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
    "cheatsheets" = {
      repo_name = "melvyndekort/cheatsheets"
      role_name = "github-actions-cheatsheets"
    }
    "cv-melvyn-dev" = {
      repo_name = "melvyndekort/cv-melvyn-dev"
      role_name = "github-actions-cv-melvyn-dev"
    }
    "dockersetup" = {
      repo_name = "melvyndekort/dockersetup"
      role_name = "github-actions-dockersetup"
    }
    "ignition" = {
      repo_name = "melvyndekort/ignition"
      role_name = "github-actions-ignition"
    }
    "mdekort-nl" = {
      repo_name = "melvyndekort/mdekort-nl"
      role_name = "github-actions-mdekort-nl"
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
    "tf-minecraft" = {
      repo_name = "melvyndekort/tf-minecraft"
      role_name = "github-actions-tf-minecraft"
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
