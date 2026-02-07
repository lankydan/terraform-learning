variable "image_pull_policy" {
  description = "Image pull policy"
  type        = string
  default     = "IfNotPresent"
}

variable "namespace" {
  description = "namespace"
  type        = string
  default     = "default"
}