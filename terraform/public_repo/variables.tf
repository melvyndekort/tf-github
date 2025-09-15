variable "name" {
  type = string
}

variable "description" {
  type = string
}

variable "force_push_bypassers" {
  type = list(string)
}

variable "allowed_actions_config" {
  type    = list(string)
  default = []
}
