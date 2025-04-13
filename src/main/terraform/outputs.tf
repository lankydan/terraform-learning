output "container_id" {
  description = "the container id"
  value       = docker_container.my-app.id
}

output "image_id" {
  description = "image id"
  value       = docker_image.my-app.id
}
