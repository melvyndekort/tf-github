# State migrations for OIDC role refactoring
# These can be removed after the first successful apply

# IAM roles: root -> module
moved {
  from = aws_iam_role.github_actions["assets"]
  to   = module.oidc_roles_075673041815.aws_iam_role.github_actions["assets"]
}
moved {
  from = aws_iam_role.github_actions["aws-ntfy-alerts"]
  to   = module.oidc_roles_075673041815.aws_iam_role.github_actions["aws-ntfy-alerts"]
}
moved {
  from = aws_iam_role.github_actions["cheatsheets"]
  to   = module.oidc_roles_075673041815.aws_iam_role.github_actions["cheatsheets"]
}
moved {
  from = aws_iam_role.github_actions["email-infra"]
  to   = module.oidc_roles_075673041815.aws_iam_role.github_actions["email-infra"]
}
moved {
  from = aws_iam_role.github_actions["example.melvyn.dev"]
  to   = module.oidc_roles_075673041815.aws_iam_role.github_actions["example.melvyn.dev"]
}
moved {
  from = aws_iam_role.github_actions["get-cookies"]
  to   = module.oidc_roles_075673041815.aws_iam_role.github_actions["get-cookies"]
}
moved {
  from = aws_iam_role.github_actions["homelab"]
  to   = module.oidc_roles_075673041815.aws_iam_role.github_actions["homelab"]
}
moved {
  from = aws_iam_role.github_actions["ignition"]
  to   = module.oidc_roles_075673041815.aws_iam_role.github_actions["ignition"]
}
moved {
  from = aws_iam_role.github_actions["melvyn-dev"]
  to   = module.oidc_roles_075673041815.aws_iam_role.github_actions["melvyn-dev"]
}
moved {
  from = aws_iam_role.github_actions["minecraft-server"]
  to   = module.oidc_roles_075673041815.aws_iam_role.github_actions["minecraft-server"]
}
moved {
  from = aws_iam_role.github_actions["startpage"]
  to   = module.oidc_roles_075673041815.aws_iam_role.github_actions["startpage"]
}
moved {
  from = aws_iam_role.github_actions["tf-aws"]
  to   = module.oidc_roles_075673041815.aws_iam_role.github_actions["tf-aws"]
}
moved {
  from = aws_iam_role.github_actions["tf-backup"]
  to   = module.oidc_roles_075673041815.aws_iam_role.github_actions["tf-backup"]
}
moved {
  from = aws_iam_role.github_actions["tf-cloudflare"]
  to   = module.oidc_roles_075673041815.aws_iam_role.github_actions["tf-cloudflare"]
}
moved {
  from = aws_iam_role.github_actions["tf-cloudtrail"]
  to   = module.oidc_roles_075673041815.aws_iam_role.github_actions["tf-cloudtrail"]
}
moved {
  from = aws_iam_role.github_actions["tf-cognito"]
  to   = module.oidc_roles_075673041815.aws_iam_role.github_actions["tf-cognito"]
}
moved {
  from = aws_iam_role.github_actions["tf-grafana"]
  to   = module.oidc_roles_075673041815.aws_iam_role.github_actions["tf-grafana"]
}

# Policy attachments: root -> module
moved {
  from = aws_iam_role_policy_attachment.github_actions_admin["assets"]
  to   = module.oidc_roles_075673041815.aws_iam_role_policy_attachment.admin["assets"]
}
moved {
  from = aws_iam_role_policy_attachment.github_actions_admin["aws-ntfy-alerts"]
  to   = module.oidc_roles_075673041815.aws_iam_role_policy_attachment.admin["aws-ntfy-alerts"]
}
moved {
  from = aws_iam_role_policy_attachment.github_actions_admin["cheatsheets"]
  to   = module.oidc_roles_075673041815.aws_iam_role_policy_attachment.admin["cheatsheets"]
}
moved {
  from = aws_iam_role_policy_attachment.github_actions_admin["email-infra"]
  to   = module.oidc_roles_075673041815.aws_iam_role_policy_attachment.admin["email-infra"]
}
moved {
  from = aws_iam_role_policy_attachment.github_actions_admin["example.melvyn.dev"]
  to   = module.oidc_roles_075673041815.aws_iam_role_policy_attachment.admin["example.melvyn.dev"]
}
moved {
  from = aws_iam_role_policy_attachment.github_actions_admin["get-cookies"]
  to   = module.oidc_roles_075673041815.aws_iam_role_policy_attachment.admin["get-cookies"]
}
moved {
  from = aws_iam_role_policy_attachment.github_actions_admin["homelab"]
  to   = module.oidc_roles_075673041815.aws_iam_role_policy_attachment.admin["homelab"]
}
moved {
  from = aws_iam_role_policy_attachment.github_actions_admin["ignition"]
  to   = module.oidc_roles_075673041815.aws_iam_role_policy_attachment.admin["ignition"]
}
moved {
  from = aws_iam_role_policy_attachment.github_actions_admin["melvyn-dev"]
  to   = module.oidc_roles_075673041815.aws_iam_role_policy_attachment.admin["melvyn-dev"]
}
moved {
  from = aws_iam_role_policy_attachment.github_actions_admin["minecraft-server"]
  to   = module.oidc_roles_075673041815.aws_iam_role_policy_attachment.admin["minecraft-server"]
}
moved {
  from = aws_iam_role_policy_attachment.github_actions_admin["startpage"]
  to   = module.oidc_roles_075673041815.aws_iam_role_policy_attachment.admin["startpage"]
}
moved {
  from = aws_iam_role_policy_attachment.github_actions_admin["tf-aws"]
  to   = module.oidc_roles_075673041815.aws_iam_role_policy_attachment.admin["tf-aws"]
}
moved {
  from = aws_iam_role_policy_attachment.github_actions_admin["tf-backup"]
  to   = module.oidc_roles_075673041815.aws_iam_role_policy_attachment.admin["tf-backup"]
}
moved {
  from = aws_iam_role_policy_attachment.github_actions_admin["tf-cloudflare"]
  to   = module.oidc_roles_075673041815.aws_iam_role_policy_attachment.admin["tf-cloudflare"]
}
moved {
  from = aws_iam_role_policy_attachment.github_actions_admin["tf-cloudtrail"]
  to   = module.oidc_roles_075673041815.aws_iam_role_policy_attachment.admin["tf-cloudtrail"]
}
moved {
  from = aws_iam_role_policy_attachment.github_actions_admin["tf-cognito"]
  to   = module.oidc_roles_075673041815.aws_iam_role_policy_attachment.admin["tf-cognito"]
}
moved {
  from = aws_iam_role_policy_attachment.github_actions_admin["tf-grafana"]
  to   = module.oidc_roles_075673041815.aws_iam_role_policy_attachment.admin["tf-grafana"]
}

# Secrets: repo_secrets -> oidc_role_arn
moved {
  from = github_actions_secret.repo_secrets["assets_aws_role_arn"]
  to   = github_actions_secret.oidc_role_arn["assets"]
}
moved {
  from = github_actions_secret.repo_secrets["aws_ntfy_alerts_aws_role_arn"]
  to   = github_actions_secret.oidc_role_arn["aws-ntfy-alerts"]
}
moved {
  from = github_actions_secret.repo_secrets["cheatsheets_aws_role_arn"]
  to   = github_actions_secret.oidc_role_arn["cheatsheets"]
}
moved {
  from = github_actions_secret.repo_secrets["email_infra_aws_role_arn"]
  to   = github_actions_secret.oidc_role_arn["email-infra"]
}
moved {
  from = github_actions_secret.repo_secrets["example_melvyn_dev_aws_role_arn"]
  to   = github_actions_secret.oidc_role_arn["example.melvyn.dev"]
}
moved {
  from = github_actions_secret.repo_secrets["get_cookies_aws_role_arn"]
  to   = github_actions_secret.oidc_role_arn["get-cookies"]
}
moved {
  from = github_actions_secret.repo_secrets["homelab_aws_role_arn"]
  to   = github_actions_secret.oidc_role_arn["homelab"]
}
moved {
  from = github_actions_secret.repo_secrets["ignition_aws_role_arn"]
  to   = github_actions_secret.oidc_role_arn["ignition"]
}
moved {
  from = github_actions_secret.repo_secrets["melvyn_dev_aws_role_arn"]
  to   = github_actions_secret.oidc_role_arn["melvyn-dev"]
}
moved {
  from = github_actions_secret.repo_secrets["minecraft_server_aws_role_arn"]
  to   = github_actions_secret.oidc_role_arn["minecraft-server"]
}
moved {
  from = github_actions_secret.repo_secrets["network_monitor_aws_role_arn"]
  to   = github_actions_secret.oidc_role_arn["network-monitor"]
}
moved {
  from = github_actions_secret.repo_secrets["startpage_aws_role_arn"]
  to   = github_actions_secret.oidc_role_arn["startpage"]
}
moved {
  from = github_actions_secret.repo_secrets["tf_aws_aws_role_arn"]
  to   = github_actions_secret.oidc_role_arn["tf-aws"]
}
moved {
  from = github_actions_secret.repo_secrets["tf_backup_aws_role_arn"]
  to   = github_actions_secret.oidc_role_arn["tf-backup"]
}
moved {
  from = github_actions_secret.repo_secrets["tf_cloudflare_aws_role_arn"]
  to   = github_actions_secret.oidc_role_arn["tf-cloudflare"]
}
moved {
  from = github_actions_secret.repo_secrets["tf_cloudtrail_aws_role_arn"]
  to   = github_actions_secret.oidc_role_arn["tf-cloudtrail"]
}
moved {
  from = github_actions_secret.repo_secrets["tf_cognito_aws_role_arn"]
  to   = github_actions_secret.oidc_role_arn["tf-cognito"]
}
moved {
  from = github_actions_secret.repo_secrets["tf_github_aws_role_arn"]
  to   = github_actions_secret.oidc_role_arn["tf-github"]
}
moved {
  from = github_actions_secret.repo_secrets["tf_grafana_aws_role_arn"]
  to   = github_actions_secret.oidc_role_arn["tf-grafana"]
}
