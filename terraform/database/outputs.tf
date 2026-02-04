output "jdbcUrl" {
  description = "The jdbcUrl of postgres"
  value       = "jdbc:postgresql://${kubernetes_service.postgres.metadata[0].name}.${var.namespace}.svc.cluster.local:${kubernetes_service.postgres.spec[0].port[0].port}/postgres"
}
