# terraform loads all .tf files in the directory

variable "container_name" {
  description = "container name"
  type = string
  default = "example-container-name"
}

variable "configuration" {
  description = "config file"
  type = any
  default = {}
}

variable "my_variable" {
  description = "Set the log message in the application"
  type        = string
  default     = "default"
}

variable "additional_environment_variables" {
  description = "extra env variables"
  type        = map(string)
  default     = {}
}

# variable "sidecar_containers" {
#   description = "Additional sidecar containers to deploy with the application"
#   type = map(object({}))
#   default = {}
# }