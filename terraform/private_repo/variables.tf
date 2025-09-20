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

variable "force_push_bypassers" {
  type    = list(string)
  default = []
}
