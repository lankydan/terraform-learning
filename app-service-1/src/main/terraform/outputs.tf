output "container_id" {
  description = "the container id"
  value       = kubernetes_deployment.my-app.id
}
