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
          image_pull_policy = var.image_pull_policy
          image             = "lankydan/learning:app-service-2_0.0.4"
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

resource "kubernetes_config_map" "liquibase_scripts" {
  metadata {
    name = "liquibase-scripts"
    namespace = var.namespace
  }

  data = {
    "changelog.xml"      = file("${path.module}/liquibase/changelog-master.xml")
    "orders-table.xml"   = file("${path.module}/liquibase/orders-table.xml")
  }
}

# Issue with what is done here, is that the application pods do not wait for the migration to complete before starting.
# Either the pods need a readiness check that depends on whether some particular tables exist or not, or the pods need
# to wait for the migration itself to complete. There doesn't seem to be a simple built in way to do this?
resource "kubernetes_job" "liquibase_migration" {
  metadata {
    # This hash ensures a new job is created whenever the scripts change
    name = "${var.app_name}-liquibase-migration-${substr(md5(jsonencode(kubernetes_config_map.liquibase_scripts.data)), 0, 8)}"
    namespace = var.namespace
  }
  spec {

    ttl_seconds_after_finished = 300

    template {

      metadata {
        labels = {
          App = "${var.app_name}-liquibase-migration"
        }
      }

      spec {
        container {
          name  = "liquibase"
          image = "liquibase/liquibase:4.20"

          # Liquibase default search path includes /liquibase/changelog
          # command = ["sh", "-c", "ls -R /liquibase/changelog && sleep 3600"]
          command = ["liquibase"]
          args = [
            "--search-path=/liquibase/changelog",
            "--changelog-file=changelog.xml",
            "--url=${var.jdbcUrl}",
            "--username=${var.username}",
            "--password=${var.password}",
            "--default-schema-name=${var.schema}",
            "update"
          ]

          volume_mount {
            name       = "scripts"
            mount_path = "/liquibase/changelog"
            read_only  = true
          }
        }

        volume {
          name = "scripts"
          config_map {
            name = kubernetes_config_map.liquibase_scripts.metadata[0].name
          }
        }

        restart_policy = "Never"
      }
    }
  }

  # Ensure the user exists and the scripts are uploaded before running
  depends_on = [
    kubernetes_config_map.liquibase_scripts
  ]
}
