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