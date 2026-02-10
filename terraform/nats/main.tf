locals {
  app_name       = "nats"
}

resource "kubernetes_deployment" "nats" {
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
        container {
          image_pull_policy = var.image_pull_policy
          image             = "nats:${var.image_tag}"
          name              = local.app_name
          args              = ["-js"] # Enable JetStream

          port {
            container_port = 4222
            name           = "client"
          }
          port {
            container_port = 8222
            name           = "metrics"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "nats" {
  metadata {
    name      = "${local.app_name}-service"
    namespace = var.namespace
    labels = {
      App = local.app_name
    }
  }
  spec {
    selector = {
      App = local.app_name
    }
    port {
      name        = "client"
      port        = 4222
      protocol    = "TCP"
      target_port = 4222
    }
    port {
      name        = "metrics"
      port        = 8222
      protocol    = "TCP"
      target_port = 8222
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_job" "nats_setup" {
  metadata {
    name      = "nats-subject-setup"
    namespace = var.namespace
  }
  spec {
    template {
      metadata {

      }
      spec {
        container {
          name  = "nats-cli"
          image = "natsio/nats-box:latest"

          # We use a shell script to check if the stream exists first
          command = ["sh", "-c"]
          args = [
            <<-EOT
            SERVER="nats://nats-service:4222"
            STREAM_NAME="ORDERS_STREAM"
            SUBJECTS="orders.*"

            echo "Checking if stream $STREAM_NAME exists..."
            if nats --server "$SERVER" stream info "$STREAM_NAME" > /dev/null 2>&1; then
              echo "Stream exists. Updating configuration..."
              nats --server "$SERVER" stream edit "$STREAM_NAME" --subjects "$SUBJECTS" --defaults
            else
              echo "Stream does not exist. Creating..."
              nats --server "$SERVER" stream add "$STREAM_NAME" --subjects "$SUBJECTS" --storage file --retention limits --defaults
            fi
            EOT
          ]
        }
        restart_policy = "Never"
      }
    }
    # If it fails due to a network blip, try 3 times
    backoff_limit = 3
  }

  # This ensures that if you change the subjects in your Terraform code,
  # the job runs again to update the stream.
  # lifecycle {
  #   replace_triggered_by = [
  #     null_resource.nats_config_trigger.id
  #   ]
  # }
}

# resource "null_resource" "nats_config_trigger" {
#   triggers = {
#     # Update this value to force a re-run of the setup job
#     config_version = "1.1"
#   }
# }
