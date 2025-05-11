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

variable "configuration" {
  description = "config file"
  type = any
  default = {}
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

variable "dockerhub_username" {
  description = "Dockerhub username"
  type        = string
  default     = ""
}

variable "dockerhub_password" {
  description = "Dockerhub password"
  type        = string
  default     = ""
}
