variable "name" {
  description = "Repository name"
  type        = string
}

variable "description" {
  description = "Repository description"
  type        = string
}

variable "visibility" {
  description = "Repository visibility: \"public\" or \"private\""
  type        = string

  validation {
    condition     = contains(["public", "private"], var.visibility)
    error_message = "visibility must be \"public\" or \"private\"."
  }
}

variable "force_push_bypassers" {
  description = "List of user node IDs that can force push. Only used when visibility = \"public\" (private repos get no branch_protection resource, matching current behaviour)."
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
    Status check contexts that must pass before main accepts a merge. Only
    used when visibility = "public". Empty (the default) keeps the previous
    behaviour of requiring no checks.
  EOT
  type        = list(string)
  default     = []
}

variable "required_review_count" {
  description = <<-EOT
    Number of approving reviews required on a pull request. Only used when
    visibility = "public". null (the default) keeps the previous behaviour
    of requiring no explicit approval count.
  EOT
  type        = number
  default     = null
}

variable "require_pull_request" {
  description = <<-EOT
    Whether main requires a pull request (with review + the configured
    status checks) before it accepts changes. Only used when
    visibility = "public" (private repos get no branch_protection resource
    at all, matching current behaviour). true (the default) is the normal,
    permanent posture for every public repo. Set false ONLY as a temporary,
    explicitly-tracked measure (e.g. a migration that needs many small
    direct commits to main) - it drops both the required-review and
    required-status-check blocks from branch protection, so main accepts
    direct pushes with no review and no CI gate. Flip back to true (or
    remove the override) as soon as the migration window closes; do not
    leave a repo running with this false.
  EOT
  type        = bool
  default     = true
}

variable "allow_forking" {
  description = <<-EOT
    Whether the repository may be forked. GitHub does not allow disabling
    forks on public repositories owned by a personal account, so for public
    repos this is expected to stay true.
  EOT
  type        = bool
  default     = true
}

variable "archived" {
  description = "Whether the repository is archived (read-only). GitHub rejects most write operations against an archived repo, so this should only ever go true -> a repo entering this state stops receiving collaborator/permission/secret updates from this module."
  type        = bool
  default     = false
}

variable "deploy_keys" {
  description = "Read-only (or read-write) deploy keys to add to the repository."
  type = list(object({
    title     = string
    key       = string
    read_only = bool
  }))
  default = []
}
