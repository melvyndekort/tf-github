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
