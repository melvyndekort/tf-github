module "dotfiles" {
  source = "./public_repo"

  name        = "dotfiles"
  description = "This repository contains all the important dotfiles in my Linux home directory based on the chezmoi dotfile manager."
  
  force_push_bypassers = [ data.github_user.melvyn.node_id ]
}
