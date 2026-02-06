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

# Output the Flink Kubernetes Operator status or endpoint if available
output "flink_operator_namespace" {
  description = "Namespace where the Flink Kubernetes Operator is deployed"
  value       = helm_release.flink_operator.namespace
}


