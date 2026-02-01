resource "kubernetes_deployment" "my-app" {
  metadata {
    name = var.app_name
    namespace = var.namespace
    labels = {
      App = var.app_name
    }
  }
  spec {
    selector {
      match_labels = {
        App = var.app_name
      }
    }
    replicas = var.replicas
    # port {
    #   port = 8080
    # }
    #
    # type = "NodePort"
    template {
      metadata {
        labels = {
          App = var.app_name
        }
      }
      spec {
        image_pull_secrets {
          name = var.image_pull_secret
        }
        container {
          image_pull_policy = "IfNotPresent"
          image             = "lankydan/learning:app-service-1_0.0.4"
          name              = var.container_name
          # Adds additional arguments to the pod, e.g. the image has already registered its own arguments and these `args`
          # are added to them.
          args = ["${local.app_config_location}/config.yml"]
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
  }
}

resource "kubernetes_service" "my-app" {
  metadata {
    name = "${var.app_name}-service"
    namespace = var.namespace
    labels = {
      App = var.app_name
    }
  }
  spec {
    port {
      name        = "http"
      port        = var.port
      protocol    = "TCP"
      target_port = var.port
    }
    selector = {
      App = var.app_name
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_config_map" "my-app" {
  count = length("configuration") > 0 ? 1 : 0
  metadata {
    name = format("%s-config-map", var.app_name)
    namespace = var.namespace
  }

  data = {
    "config.yml" = length(var.configuration) > 0 ? yamlencode(var.configuration) : yamlencode(local.config)
  }
}
