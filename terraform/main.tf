# Provider can only exist in the top level terraform, so it has been moved here from `../src/main/terraform`.
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "docker-desktop"
}

resource "kubernetes_namespace" "my-app-namespace" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_secret" "docker_registry" {
  metadata {
    name = "docker-registry-secret"
    namespace = var.namespace
  }

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "https://index.docker.io/v1/" = {
          auth = base64encode("${var.dockerhub_username}:${var.dockerhub_password}")
        }
      }
    })
  }
  type = "kubernetes.io/dockerconfigjson"
}

# Run apply from this terraform directory to run this module
module "app-service-1" {
  source                           = "../app-service-1/src/main/terraform"
  container_name = var.container_name
  # Configuration, or any of these variables could be hard coded here
  configuration                    = var.configuration
  port                             = var.app_port
  additional_environment_variables = var.additional_environment_variables
  replicas                         = var.replicas
  app_name                         = var.app_name_1
  app_service_2_url                = "${var.app_name_2}-service.${var.namespace}.svc.cluster.local:${var.app_port}"
  namespace                        = var.namespace
  image_pull_secret                = kubernetes_secret.docker_registry.metadata[0].name
}

module "app-service-2" {
  source                           = "../app-service-2/src/main/terraform"
  container_name = var.container_name
  # Configuration, or any of these variables could be hard coded here
  configuration                    = var.configuration
  port                             = var.app_port
  additional_environment_variables = var.additional_environment_variables
  replicas                         = var.replicas
  app_name                         = var.app_name_2
  namespace                        = var.namespace
  image_pull_secret                = kubernetes_secret.docker_registry.metadata[0].name
}

module "nginx" {
  source         = "./external-dependencies/nginx"
  container_name = var.container_name
  app_name_1     = var.app_name_1
  app_port       = var.app_port
  replicas       = 2
  namespace      = var.namespace
}