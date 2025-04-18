output "container_id" {
  description = "the container id"
  # Reference the module to take the outputs it creates and output them here as well.
  value       = module.my-app.container_id
}
