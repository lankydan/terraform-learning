variable "namespace" {
  description = "namespace"
  type        = string
  default     = "default"
}

variable "ingress_paths" {
  description = "List of ingress paths with service name and port"
  type = list(object({
    path         = string
    service_name = string
    service_port = number
  }))
  default = []
}

variable "ingress_namespace" {
  description = "namespace for ingress"
  type        = string
  default     = "ingress-nginx"
}

variable "replicas" {
  description = "number of replicas"
  type        = number
  default     = 1
}