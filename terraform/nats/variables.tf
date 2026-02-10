
variable "namespace" {
  description = "Kubernetes namespace for the NATS deployment"
  type        = string
  default     = "default"
}

variable "image_tag" {
  description = "NATS Docker image tag"
  type        = string
  default     = "2.10"
}

variable "image_pull_policy" {
  description = "Image pull policy for NATS deployment"
  type        = string
  default     = "IfNotPresent"
}

variable "replicas" {
  description = "Number of NATS replicas"
  type        = number
  default     = 1
}

variable "stream_name" {
  description = "The name of the NATS stream"
  type        = string
  default     = "SONG_EVENTS"
}

variable "stream_subjects" {
  description = "The subjects for the NATS stream"
  type        = string
  default     = "song.events"
}
