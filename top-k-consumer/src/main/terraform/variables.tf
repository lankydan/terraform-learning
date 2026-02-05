# terraform/flink/variables.tf

variable "docker_repository" {
  description = "The Docker repository to push Flink job images to (e.g., your_username/your_repo)."
  type        = string
  default     = "lankydan/learning" # As per your example
}

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
  type        = string
  default     = "default"
}