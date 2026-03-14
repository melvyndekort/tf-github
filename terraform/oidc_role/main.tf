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
      values   = ["repo:${var.github_org}/${each.key}:ref:refs/heads/main"]
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
