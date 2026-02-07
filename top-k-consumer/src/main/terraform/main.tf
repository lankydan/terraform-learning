# terraform/flink/main.tf

resource "helm_release" "flink_operator" {
  name       = "flink-kubernetes-operator"
  chart      = "https://archive.apache.org/dist/flink/flink-kubernetes-operator-1.13.0/flink-kubernetes-operator-1.13.0-helm.tgz"
  # namespace  = "flink-operator-system"
  # create_namespace = true
  namespace = var.namespace
  version    = "1.13.0" # Explicitly set the version from the URL
  set = [{
    name  = "webhook.create"
    value = "false"
  }]

  # set = {
  #   name  = "watchNamespaces"
  #   value = "{default}"
  # }
}
# image_pull_secrets {
#   name = var.image_pull_secret
# }

# resource "kubernetes_manifest" "flink_cluster" {
#   manifest = {
#     apiVersion = "flink.apache.org/v1beta1"
#     kind       = "FlinkDeployment"
#     metadata = {
#       name      = "top-k-consumer-flink-app"
#       namespace = "default"
#     }
#     spec = {
#       image = "${var.docker_repository}/top-k-consumer:1.0-SNAPSHOT" # Image will be built and pushed by Gradle
#       flinkVersion = "v1_17"
#       flinkConfiguration = {
#         "taskmanager.numberOfTaskSlots" = "1"
#       }
#       # serviceAccount = "flink"
#       jobManager = {
#         resource = { memory = "1024m", cpu = 1 }
#         replication = 1
#       }
#       taskManager = {
#         resource = { memory = "1024m", cpu = 1 }
#         replication = 1
#       }
#       mode = "Application"
#       job = {
#         jarURI = "local:///opt/flink/usrlib/flink-job-1.0-SNAPSHOT.jar"
#         entryClass = "org.example.MainKt"
#         parallelism = 1
#         upgradeMode = "stateless"
#         allowNonRestoredState = true
#       }
#     }
#   }
#   depends_on = [
#     helm_release.flink_operator,
#     # The Docker image is now expected to be pre-built and pushed by Gradle
#   ]
# }

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
          image_pull_policy = var.image_pull_policy
          name  = "jobmanager"
          # image = "flink:latest"
          image = "lankydan/learning:top-k-consumer-flink_1.0-SNAPSHOT"
          # args  = ["jobmanager"]

          args = [
            "standalone-job",
            "--job-classname", "org.example.MainKt", # Your entry point class
            # "--job-id", "optional-static-job-id",
            # "--allowNonRestoredState"
          ]

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
          name  = "taskmanager"
          # image = "flink:latest"
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
    EOT

    "app-config.yaml" = yamlencode(
      {
        persistence = {
          intervalSeconds = 3
        }
      }
    )

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
    # Need these in here as well?
    # jobmanager.rpc.address: flink-jobmanager
    # execution.target: kubernetes-session
    # # If you are not using a custom image, you might need to specify the pipeline JAR
    # # pipeline.jars: "local:///opt/flink/usrlib/my-job.jar"
  }
}