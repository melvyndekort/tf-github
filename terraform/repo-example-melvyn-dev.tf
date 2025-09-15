module "example_melvyn_dev" {
  source = "./public_repo"

  name        = "example.melvyn.dev"
  description = "Example static website"
  
  force_push_bypassers = [ data.github_user.melvyn.node_id ]
}
