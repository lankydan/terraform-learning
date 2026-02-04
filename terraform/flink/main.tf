# terraform/flink/main.tf

resource "helm_release" "flink_operator" {
  name       = "flink-kubernetes-operator"
  repository = "https://downloads.apache.org/flink/flink-kubernetes-operator-1.7.0" # latest is 1.15.0
  chart      = "flink-kubernetes-operator"
  namespace  = "flink-operator-system"
  create_namespace = true

  set {
    name  = "watchNamespaces"
    value = "{default}"
  }
}

resource "kubernetes_manifest" "flink_cluster" {
  manifest = {
    apiVersion = "flink.apache.org/v1beta1"
    kind       = "FlinkDeployment"
    metadata = {
      name      = "basic-example"
      namespace = "default"
    }
    spec = {
      image = "flink:1.17" # This assumes a standard Flink image.
      flinkVersion = "v1_17"
      jobManager = {
        resource = { memory = "1024m", cpu = 1 }
      }
      taskManager = {
        resource = { memory = "1024m", cpu = 1 }
      }
      job = {
        # This jarURI assumes the 'flink-job-1.0-SNAPSHOT.jar' is made available
        # inside the Flink TaskManager/JobManager pods.
        # This typically requires either:
        # 1. Building a custom Flink Docker image that includes this JAR.
        # 2. Mounting the JAR into the pods via a Persistent Volume.
        # Since "no explicit docker commands" was requested, this Terraform config
        # does not manage the creation of such a custom image or volume.
        # The user would need to ensure the JAR is present at this path within the Flink container.
        jarURI = "local:///opt/flink/usrlib/flink-job-1.0-SNAPSHOT.jar"
        entryClass = "org.example.MainKt" # Specify the main class of the Flink job
        parallelism = 1 # Set to 1 for simplicity for local testing
        upgradeMode = "stateless"
      }
    }
  }
  depends_on = [helm_release.flink_operator]
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
