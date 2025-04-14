# terraform loads all .tf files in the directory

variable "container_name" {
  description = "container name"
  type = string
  default = "example-container-name"
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