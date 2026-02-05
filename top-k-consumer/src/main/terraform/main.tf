# terraform/flink/main.tf

resource "helm_release" "flink_operator" {
  name       = "flink-kubernetes-operator"
  repository = "https://downloads.apache.org/flink/flink-kubernetes-operator-1.13.0"
  chart      = "flink-kubernetes-operator"
  namespace  = "flink-operator-system"
  create_namespace = true

  # set = {
  #   name  = "watchNamespaces"
  #   value = "{default}"
  # }
}
# image_pull_secrets {
#   name = var.image_pull_secret
# }
resource "kubernetes_manifest" "flink_cluster" {
  manifest = {
    apiVersion = "flink.apache.org/v1beta1"
    kind       = "FlinkDeployment"
    metadata = {
      name      = "top-k-consumer-flink-app"
      namespace = "default"
    }
    spec = {
      image = "${var.docker_repository}/top-k-consumer:1.0-SNAPSHOT" # Image will be built and pushed by Gradle
      flinkVersion = "v1_17"
      flinkConfiguration = {
        "taskmanager.numberOfTaskSlots" = "1"
      }
      serviceAccount = "flink"
      jobManager = {
        resource = { memory = "1024m", cpu = 1 }
        replication = 1
      }
      taskManager = {
        resource = { memory = "1024m", cpu = 1 }
        replication = 1
      }
      mode = "Application"
      job = {
        jarURI = "local:///opt/flink/usrlib/flink-job-1.0-SNAPSHOT.jar"
        entryClass = "org.example.MainKt"
        parallelism = 1
        upgradeMode = "stateless"
        allowNonRestoredState = true
      }
    }
  }
  depends_on = [
    helm_release.flink_operator,
    # The Docker image is now expected to be pre-built and pushed by Gradle
  ]
}

# Output the Flink Kubernetes Operator status or endpoint if available
output "flink_operator_namespace" {
  description = "Namespace where the Flink Kubernetes Operator is deployed"
  value       = helm_release.flink_operator.namespace
}

output "flink_deployment_name" {
  description = "Name of the FlinkDeployment custom resource"
  value       = kubernetes_manifest.flink_cluster.manifest.metadata.name
}
