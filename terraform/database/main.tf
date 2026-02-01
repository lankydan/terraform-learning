resource "kubernetes_deployment" "postgres" {
  metadata {
    name      = local.postgres_name
    namespace = var.namespace
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = local.postgres_name
      }
    }

    template {
      metadata {
        labels = {
          app = local.postgres_name
        }
      }

      spec {
        container {
          name  = "postgres"
          image = "postgres:15"

          # Needs secrets or something to obfuscate the password
          env {
            name  = "POSTGRES_USER"
            value = "postgres"
            # value_from {
            #   secret_key_ref {
            #     name = var.user_passwords_secret
            #     key  = "admin_username"
            #   }
            # }
          }

          env {
            name  = "POSTGRES_PASSWORD"
            value = "postgres"
            # value_from {
            #   secret_key_ref {
            #     name = var.user_passwords_secret
            #     key  = "admin_password"
            #   }
            # }
          }

          env {
            name  = "POSTGRES_DB"
            value = "postgres"
          }

          volume_mount {
            name       = local.volume_name
            mount_path = local.volume_path
          }
        }

        volume {
          name = local.volume_name
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.postgres.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "postgres" {
  metadata {
    name      = local.postgres_name
    namespace = var.namespace
  }

  spec {
    selector = {
      app = local.postgres_name
    }

    port {
      protocol    = "TCP"
      port        = 5432
      target_port = 5432
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_persistent_volume_claim" "postgres" {
  metadata {
    name      = local.postgres_name
    namespace = var.namespace
  }

  spec {
    # Allows only a single node to read/write to the volume, although multiple pods can use it concurrently
    # if they are on the same node.
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }
}