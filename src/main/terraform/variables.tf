# terraform loads all .tf files in the directory

variable "container_name" {
  description = "container name"
  type = string
  default = "example-container-name"
}