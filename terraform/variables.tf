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

variable "port" {
  description = "Webserver port"
  type        = number
  default     = 8080
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

variable "nginx_configuration" {
  description = "config file for nginx"
  type = any
  default = {}
}