variable "name" {
  type = string
}

variable "description" {
  type = string
}

variable "allowed_actions_config" {
  type    = list(string)
  default = []
}

variable "deploy_keys" {
  type = list(object({
    title     = string
    key       = string
    read_only = bool
  }))
  default = []
}

variable "allow_forking" {
  description = "Whether the repository may be forked. Private repos gain nothing from forks."
  type        = bool
  default     = true
}

variable "archived" {
  description = "Whether the repository is archived (read-only). GitHub rejects most write operations against an archived repo, so this should only ever go true -> a repo entering this state stops receiving collaborator/permission/secret updates from this module."
  type        = bool
  default     = false
}
