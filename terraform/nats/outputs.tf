
output "nats_url" {
  description = "The URL of the NATS server within the Kubernetes cluster"
  value       = "nats://${kubernetes_service.nats.metadata[0].name}.${var.namespace}.svc.cluster.local:4222"
}
