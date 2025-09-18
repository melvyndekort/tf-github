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
