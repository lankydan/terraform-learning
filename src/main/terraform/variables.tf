# terraform loads all .tf files in the directory

variable "container_name" {
  description = "container name"
  type = string
  default = "example-container-name"
}

variable "app_name" {
  description = "application name"
  type = string
  default = "my-app"
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

variable "replicas" {
  description = "The number of replicas"
  type        = number
  default     = 1
}