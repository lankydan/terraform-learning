# terraform loads all .tf files in the directory

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

variable "image_pull_secret" {
  description = "Image pull secret"
  type        = string
  default     = "docker-registry-secret"
}

## database start

variable "jdbcUrl" {
  description = "jdbcUrl"
  type        = string
}

variable "schema" {
  description = "schema"
  type        = string
}

variable "username" {
  description = "username"
  type        = string
}

variable "password" {
  description = "password"
  type        = string
}

## database end