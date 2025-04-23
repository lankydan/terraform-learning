variable "namespace" {
  description = "namespace"
  type = string
  default = "default"
}

variable "container_name" {
  description = "container name"
  type = string
  default = "example-container-name"
}

variable "app_name_1" {
  description = "application name"
  type = string
  default = "my-app-1"
}

variable "app_port" {
  description = "Webserver port"
  type        = number
  default     = 8080
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