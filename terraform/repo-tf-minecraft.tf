module "tf_minecraft" {
  source = "./public_repo"

  name        = "tf-minecraft"
  description = "A Minecraft server on AWS ECS"
  
  force_push_bypassers = [ data.github_user.melvyn.node_id ]
}

resource "github_actions_secret" "tf_minecraft_role_arn" {
  repository      = module.tf_minecraft.repo_name
  secret_name     = "AWS_ROLE_ARN"
  plaintext_value = "arn:aws:iam::075673041815:role/external/github-actions-tf-minecraft"
}

