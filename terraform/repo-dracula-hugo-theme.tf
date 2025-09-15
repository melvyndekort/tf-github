module "dracula_hugo_theme" {
  source = "./public_repo"

  name        = "dracula-hugo-theme"
  description = "My Dracula theme for Hugo static site generator"
  
  force_push_bypassers = [ data.github_user.melvyn.node_id ]
}
