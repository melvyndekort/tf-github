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
