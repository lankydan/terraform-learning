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

# I'll need to set some variables for my docker container so i can input things to my container?
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
      image             = "my-app:0.0.5"
      name              = var.container_name
      args = ["${local.app_config_location}/config.yml"]
      env {
        name  = "MY_VARIABLE"
        value = var.my_variable
      }
      # Dynamic environment variables are useful if we have a module that doesn't know about what environment variables
      # the underlying application has, which is the case when you have a generic module that runs any application.
      dynamic "env" {
        for_each = var.additional_environment_variables
        content {
          name  = env.key
          value = env.value
        }
      }
      # Use `dynamic "volume_mount" if we want configuration to be optional (uses a for each over configuration).
      volume_mount {
        mount_path = local.app_config_location
        name       = local.app_config_volume
      }
    }
    # Use `dynamic "volume" if we want configuration to be optional (uses a for each over configuration).
    volume {
      name = local.app_config_volume
      config_map {
        name = kubernetes_config_map.my-app[0].metadata[0].name
      }
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
      port = 8080
    }

    type = "NodePort"
  }

  depends_on = [
    kubernetes_pod.my-app
  ]
}

resource "kubernetes_config_map" "my-app" {
  count = length("configuration") > 0 ? 1 : 0
  metadata {
    name = format("%s-config-map", var.container_name)
  }

  data = {
    "config.yml" = length(var.configuration) > 0 ? yamlencode(var.configuration) : yamlencode(local.config)
  }
}