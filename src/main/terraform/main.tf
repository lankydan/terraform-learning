# terraform {
#   required_providers {
#     docker = {
#       source = "kreuzwerker/docker"
#       version = "~> 3.0.1"
#     }
#   }
# }
#
# provider "docker" {}
#
# resource "docker_image" "my-app" {
#   name         = "my-app:latest"
#   keep_locally = false
# }
#
# resource "docker_container" "my-app" {
#   image = docker_image.my-app.image_id
#   name  = var.container_name
#   # ports {
#   #   internal = 80
#   #   external = 8080
#   # }
# }

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "docker-desktop"
}

resource "kubernetes_pod" "my-app" {
  metadata {
    name = var.container_name
    labels = {
      app = "my-app"
    }
  }
  spec {
    container {
      image_pull_policy = "IfNotPresent"
      image = "my-app:latest"
      name  = var.container_name
    }
  }
}

resource "kubernetes_service" "my-app" {
  metadata {
    name = "my-app"
  }
  spec {
    selector = {
      app = kubernetes_pod.my-app.metadata.0.labels.app
    }
    port {
      port        = 8080
    }

    type = "NodePort"
  }

  depends_on = [
    kubernetes_pod.my-app
  ]
}