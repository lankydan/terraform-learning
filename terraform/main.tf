# Provider can only exist in the top level terraform, so it has been moved here from `../src/main/terraform`.
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "docker-desktop"
}

# Run apply from this terraform directory to run this module
module "my-app" {
  source = "../app-service-1/src/main/terraform"
  container_name = var.container_name
  # Configuration, or any of these variables could be hard coded here
  configuration = var.configuration
  port = var.app_port
  additional_environment_variables = var.additional_environment_variables
  replicas = var.replicas
  app_name = var.app_name
  namespace = var.namespace
}

resource "kubernetes_namespace" "my-app-namespace" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_deployment" "nginx" {
  metadata {
    name = "my-nginx"
    namespace = var.namespace
    labels = {
      App = "${var.container_name}-nginx"
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        App = "${var.container_name}-nginx"
      }
    }
    template {
      metadata {
        labels = {
          App = "${var.container_name}-nginx"
        }
      }
      spec {
        container {
          image = "nginx:1.27.5"
          name  = "my-nginx"
          image_pull_policy = "Always"

          port {
            container_port = 80
          }

          volume_mount {
            mount_path = local.nginx_config_location
            name       = local.nginx_config_volume
          }

          # resources {
          #   limits = {
          #     cpu    = "0.5"
          #     memory = "512Mi"
          #   }
          #   requests = {
          #     cpu    = "250m"
          #     memory = "50Mi"
          #   }
          # }
        }
        volume {
          name = local.nginx_config_volume
          config_map {
            name = kubernetes_config_map.nginx[0].metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "nginx" {
  metadata {
    name = "nginx-example"
    namespace = var.namespace
  }
  spec {
    selector = {
      App = kubernetes_deployment.nginx.spec.0.template.0.metadata[0].labels.App
    }
    port {
      node_port   = 30201
      port        = 80
      target_port = 80
    }

    type = "NodePort"
  }
}

resource "kubernetes_config_map" "nginx" {
  count = length("nginx_configuration") > 0 ? 1 : 0
  metadata {
    name = format("%s-config-map", "${var.container_name}-nginx")
    namespace = var.namespace
  }

  data = {
    "default.conf" = local.nginx_config
  }
}