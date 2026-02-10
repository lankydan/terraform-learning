# Not sure I actually need this operator
resource "helm_release" "flink_operator" {
  name      = "flink-kubernetes-operator"
  chart     = "https://archive.apache.org/dist/flink/flink-kubernetes-operator-1.13.0/flink-kubernetes-operator-1.13.0-helm.tgz"
  namespace = var.namespace
  version = "1.13.0"
  set = [
    {
      name  = "webhook.create"
      value = "false"
    }
  ]
}

# Output the Flink Kubernetes Operator status or endpoint if available
output "flink_operator_namespace" {
  description = "Namespace where the Flink Kubernetes Operator is deployed"
  value       = helm_release.flink_operator.namespace
}

resource "kubernetes_deployment" "flink_jobmanager" {
  metadata {
    name = "flink-jobmanager"
    namespace = var.namespace
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app       = "flink"
        component = "jobmanager"
      }
    }
    template {
      metadata {
        labels = {
          app       = "flink"
          component = "jobmanager"
        }
      }
      spec {
        container {
          # image_pull_policy = var.image_pull_policy
          image_pull_policy = "Always"
          name  = "jobmanager"
          image = "lankydan/learning:top-k-consumer-flink_1.0-SNAPSHOT"

          args = ["standalone-job", "--job-classname", "org.example.MainKt"]

          port {
            container_port = 6123
            name           = "rpc"
          }
          port {
            container_port = 6124
            name           = "blob-server"
          }
          port {
            container_port = 8081
            name           = "webui"
          }

          volume_mount {
            name       = "flink-config-volume"
            mount_path = "/opt/flink/conf"
          }

          # Environmental variable to point Flink to the config directory
          env {
            name  = "FLINK_CONF_DIR"
            value = "/opt/flink/conf"
          }
        }

        volume {
          name = "flink-config-volume"
          config_map {
            name = kubernetes_config_map.flink_config.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "flink_jobmanager" {
  metadata {
    name = "flink-jobmanager"
    namespace = var.namespace
  }
  spec {
    type = "ClusterIP"
    selector = {
      app       = "flink"
      component = "jobmanager"
    }
    port {
      name = "rpc"
      port = 6123
    }
    port {
      name = "blob-server"
      port = 6124
    }
    port {
      name = "webui"
      port = 8081
    }
  }
}

resource "kubernetes_deployment" "flink_taskmanager" {
  metadata {
    name = "flink-taskmanager"
    namespace = var.namespace
  }
  spec {
    replicas = 2 # Scale this for more processing power
    selector {
      match_labels = {
        app       = "flink"
        component = "taskmanager"
      }
    }
    template {
      metadata {
        labels = {
          app       = "flink"
          component = "taskmanager"
        }
      }
      spec {
        container {
          # image_pull_policy = var.image_pull_policy
          image_pull_policy = "Always"
          name  = "taskmanager"
          image = "lankydan/learning:top-k-consumer-flink_1.0-SNAPSHOT"
          args  = ["taskmanager"]

          port {
            container_port = 6122
            name           = "rpc"
          }

          volume_mount {
            name       = "flink-config-volume"
            mount_path = "/opt/flink/conf"
          }
        }

        volume {
          name = "flink-config-volume"
          config_map {
            name = kubernetes_config_map.flink_config.metadata[0].name
          }
        }
      }
    }
  }
}

#  Exception in thread "main" org.apache.flink.configuration.IllegalConfigurationException: The Flink config file '/opt/flink/conf/flink-conf.yaml' (/opt/flink/conf/flink-conf.yaml) does not exist.

resource "kubernetes_config_map" "flink_config" {
  metadata {
    name = "flink-config"
    namespace = var.namespace
    labels = {
      app = "flink"
    }
  }

  data = {
    # "config.yaml" = <<-EOT
    "flink-conf.yaml" = <<-EOT
      jobmanager.rpc.address: flink-jobmanager
      taskmanager.numberOfTaskSlots: 2
      blob.server.port: 6124
      jobmanager.rpc.port: 6123
      taskmanager.rpc.port: 6122
      jobmanager.memory.process.size: 1600m
      taskmanager.memory.process.size: 1728m
      parallelism.default: 4
      env.java.opts: --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.util.concurrent.atomic=ALL-UNNAMED

    EOT

    "config.yaml" = <<-EOT
      jobmanager.rpc.address: flink-jobmanager
      execution.target: kubernetes-session
      taskmanager.numberOfTaskSlots: 2
      blob.server.port: 6124
      jobmanager.rpc.port: 6123
      taskmanager.rpc.port: 6122
      jobmanager.memory.process.size: 1600m
      taskmanager.memory.process.size: 1728m
      parallelism.default: 4
      env.java.opts: --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.util.concurrent.atomic=ALL-UNNAMED
    EOT

    "app-config.yaml" = local_file.config.content,

    "log4j-console.properties" = <<-EOT
      # This affects logging for both user code and Flink
      rootLogger.level = INFO
      rootLogger.appenderRef.console.ref = ConsoleAppender
      rootLogger.appenderRef.rolling.ref = RollingFileAppender

      logger.pekko.name = org.apache.pekko
      logger.pekko.level = INFO
      logger.kafka.name= org.apache.kafka
      logger.kafka.level = INFO
      logger.hadoop.name = org.apache.hadoop
      logger.hadoop.level = INFO
      logger.zookeeper.name = org.apache.zookeeper
      logger.zookeeper.level = INFO

      # Log all infos to the console
      appender.console.name = ConsoleAppender
      appender.console.type = CONSOLE
      appender.console.layout.type = PatternLayout
      appender.console.layout.pattern = %d{yyyy-MM-dd HH:mm:ss,SSS} %-5p %-60c %x - %m%n

      # Log all infos in the given rolling file
      appender.rolling.name = RollingFileAppender
      appender.rolling.type = RollingFile
      appender.rolling.append = false
      appender.rolling.fileName = $${sys:log.file}
      appender.rolling.filePattern = $${sys:log.file}.%i
      appender.rolling.layout.type = PatternLayout
      appender.rolling.layout.pattern = %d{yyyy-MM-dd HH:mm:ss,SSS} %-5p %-60c %x - %m%n
      appender.rolling.policies.type = Policies
      appender.rolling.policies.size.type = SizeBasedTriggeringPolicy
      appender.rolling.policies.size.size=100MB
      appender.rolling.strategy.type = DefaultRolloverStrategy
      appender.rolling.strategy.max = 10

      # Suppress the irrelevant (wrong) warnings from the Netty channel handler
      logger.netty.name = org.jboss.netty.channel.DefaultChannelPipeline
      logger.netty.level = OFF
    EOT
      }
    }
    
    resource "local_file" "config" {
      content  = templatefile("${path.module}/config.tftpl", {
        nats_url = var.nats_url,
        nats_subject = var.nats_subject
      })
      filename = "${path.module}/app-config.yaml"
    }
    