output "role_arns" {
  value = { for k, v in aws_iam_role.github_actions : k => v.arn }
}

output "plan_role_arns" {
  value = { for k, v in aws_iam_role.github_actions_plan : k => v.arn }
}
