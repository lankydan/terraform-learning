variable "namespace" {
  description = "namespace"
  type        = string
  default     = "default"
}

variable "user_passwords_secret" {
  description = "user passwords secret"
  type        = string
}

variable "schema" {
  description = "schema name"
  type        = string
}