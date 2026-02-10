locals {
  app_name = "top-k-publisher"
}

resource "kubernetes_deployment" "top-k-publisher" {
  metadata {
    name      = local.app_name
    namespace = var.namespace
    labels = {
      App = local.app_name
    }
  }
  spec {
    selector {
      match_labels = {
        App = local.app_name
      }
    }
    replicas = var.replicas
    template {
      metadata {
        labels = {
          App = local.app_name
        }
      }
      spec {
        image_pull_secrets {
          name = var.image_pull_secret
        }
        container {
          image_pull_policy = var.image_pull_policy
          # image             = "${var.docker_repository}:top-k-publisher:${var.image_tag}"
          image             = "${var.docker_repository}:top-k-publisher_${var.image_tag}"
          name              = local.app_name
          args              = ["/app/config/config.yaml"]
          volume_mount {
            mount_path = "/app/config"
            name       = "config-volume"
          }
        }
        volume {
          name = "config-volume"
          config_map {
            name = kubernetes_config_map.top-k-publisher-config.metadata[0].name
          }
        }
      }
    }
  }
}



resource "kubernetes_config_map" "top-k-publisher-config" {
  metadata {
    name      = "${local.app_name}-config"
    namespace = var.namespace
  }
  data = {
    "config.yaml" = templatefile("${path.module}/config.tftpl", {
      nats_url     = var.nats_url,
      nats_subject = var.nats_subject
    })
  }
}