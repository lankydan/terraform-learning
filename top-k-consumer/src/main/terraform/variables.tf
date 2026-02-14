variable "image_pull_secret" {
  description = "Image pull secret"
  type        = string
  default     = "docker-registry-secret"
}

variable "image_pull_policy" {
  description = "Image pull policy"
  type        = string
  default     = "IfNotPresent"
}

variable "namespace" {
  description = "namespace"
  type = string
}

variable "nats_url" {
  description = "The URL of the NATS server"
  type = string
}

variable "nats_subject" {
  description = "The NATS subject to subscribe to"
  type = string
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
