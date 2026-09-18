variable "github_org" {
  type = string
}

variable "github_owner_id" {
  type = number
}

variable "repos" {
  description = "Map of repo name to its numeric GitHub repo_id"
  type        = map(number)
}
