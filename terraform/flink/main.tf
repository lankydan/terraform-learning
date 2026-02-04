# terraform/flink/main.tf

# This configuration assumes the Docker provider is configured in the root or a parent module.
# For simplicity, we're defining Docker containers for a local Flink setup.
# In a real-world scenario, you would provision cloud VMs (e.g., AWS EC2, GCP Compute Engine)
# and deploy Flink on them, possibly using EKS/GKE for Kubernetes deployments.

# Build the custom Flink image with the top-k-consumer job JAR
resource "docker_image" "flink_job_image" {
  name = "flink-job-runner:latest"
  build {
    context    = "../../top-k-consumer" # Path to the Dockerfile and build context
    dockerfile = "Dockerfile"
  }
  # Trigger rebuild if the JAR changes
  triggers = {
    # Using a hash of the JAR file as a trigger
    # This assumes the JAR is built before terraform apply
    jar_hash = filebase64sha256("../../top-k-consumer/build/libs/flink-job-1.0-SNAPSHOT.jar")
  }
}

# Flink JobManager Container
resource "docker_container" "flink_jobmanager" {
  name  = "flink_jobmanager"
  image = docker_image.flink_job_image.name # Use the custom image
  ports {
    internal = 8081
    external = 8081 # Flink Web UI
  }
  command = ["jobmanager"]
  env = [
    "FLINK_PROPERTIES=jobmanager.rpc.address: flink_jobmanager"
  ]
  networks_advanced {
    name = docker_network.flink_network.name
  }
}

# Flink TaskManager Container
resource "docker_container" "flink_taskmanager" {
  name  = "flink_taskmanager"
  image = docker_image.flink_job_image.name # Use the custom image
  command = ["taskmanager"]
  env = [
    "FLINK_PROPERTIES=jobmanager.rpc.address: flink_jobmanager",
    "TASK_MANAGER_NUMBER_OF_TASK_SLOTS=2" # Number of slots per TaskManager
  ]
  networks_advanced {
    name = docker_network.flink_network.name
  }
  depends_on = [docker_container.flink_jobmanager]
}

# Docker Network for Flink containers
resource "docker_network" "flink_network" {
  name = "flink-network"
  attachable = true
}

# Submit the Flink job
resource "null_resource" "submit_flink_job" {
  depends_on = [
    docker_container.flink_jobmanager,
    docker_container.flink_taskmanager # Wait for TaskManager to be ready as well
  ]

  provisioner "local-exec" {
    # This command will execute on the machine running Terraform
    command = "docker exec ${docker_container.flink_jobmanager.name} /opt/flink/bin/flink run -d -c org.example.MainKt /opt/flink/opt/flink-job-1.0-SNAPSHOT.jar"
    # The -d flag runs the job in detached mode
  }
}

# Output the JobManager UI URL
output "flink_jobmanager_ui_url" {
  description = "URL for the Flink JobManager Web UI"
  value       = "http://localhost:8081" # Assuming Docker is running locally
}

