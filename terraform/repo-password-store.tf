module "password_store" {
  source = "./private_repo"

  name        = "password-store"
  description = "Password management should be simple and follow Unix philosophy"
}
