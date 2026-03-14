output "role_arns" {
  value = { for k, v in aws_iam_role.github_actions : k => v.arn }
}
