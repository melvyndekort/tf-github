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
