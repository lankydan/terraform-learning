terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {}

resource "docker_image" "my-app" {
  name         = "my-app:latest"
  keep_locally = false
}

resource "docker_container" "my-app" {
  image = docker_image.my-app.image_id
  name  = var.container_name
  # ports {
  #   internal = 80
  #   external = 8080
  # }
}
