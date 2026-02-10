
variable "namespace" {
  description = "Kubernetes namespace for the application"
  type        = string
  default     = "default"
}

variable "image_pull_secret" {
  description = "Name of the Kubernetes secret for Docker image pull"
  type        = string
  default     = "docker-registry-secret"
}

variable "image_pull_policy" {
  description = "Policy for pulling Docker images (e.g., Always, IfNotPresent)"
  type        = string
  default     = "IfNotPresent"
}

variable "replicas" {
  description = "Number of application replicas"
  type        = number
  default     = 1
}

variable "docker_repository" {
  description = "The Docker repository to push images to"
  type        = string
}

variable "image_tag" {
  description = "The Docker image tag"
  type        = string
  default     = "1.0-SNAPSHOT"
}


variable "nats_url" {
  description = "The URL of the NATS server"
  type        = string
}

variable "nats_subject" {
  description = "The NATS subject to publish to"
  type        = string
}
