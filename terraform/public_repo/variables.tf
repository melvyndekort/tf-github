variable "name" {
  description = "Repository name"
  type        = string
}

variable "description" {
  description = "Repository description"
  type        = string
}

variable "force_push_bypassers" {
  description = "List of user node IDs that can force push"
  type        = list(string)
  default     = []
}

variable "allowed_actions_config" {
  description = "Allowed actions configuration"
  type        = list(string)
  default     = []
}

variable "required_status_checks" {
  description = <<-EOT
    Status check contexts that must pass before main accepts a merge. Empty
    (the default) keeps the previous behaviour of requiring no checks.
  EOT
  type        = list(string)
  default     = []
}

variable "required_review_count" {
  description = <<-EOT
    Number of approving reviews required on a pull request. null (the default)
    keeps the previous behaviour of requiring no explicit approval count.
  EOT
  type        = number
  default     = null
}

variable "allow_forking" {
  description = <<-EOT
    Whether the repository may be forked. GitHub does not allow disabling forks
    on public repositories owned by a personal account, so for public repos
    this is expected to stay true.
  EOT
  type        = bool
  default     = true
}
