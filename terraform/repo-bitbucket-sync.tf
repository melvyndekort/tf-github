module "bitbucket_sync" {
  source = "./private_repo"

  name        = "bitbucket-sync"
  description = "Sync all non-archived bitbucket repositories to local machine"
}
