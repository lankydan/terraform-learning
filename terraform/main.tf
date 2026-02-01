# Provider can only exist in the top level terraform, so it has been moved here from `../src/main/terraform`.
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "docker-desktop"
}

provider "helm" {
  kubernetes = {
    config_path    = "~/.kube/config"
    config_context = "docker-desktop"
  }
}

provider "random" {}

resource "kubernetes_namespace" "my-app-namespace" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_namespace" "ingress-nginx-namespace" {
  metadata {
    name = "${var.namespace}-ingress"
  }
}

resource "kubernetes_secret" "docker_registry" {
  metadata {
    name      = "docker-registry-secret"
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

resource "kubernetes_secret" "postgres" {
  metadata {
    name      = "postgres-secret"
    namespace = var.namespace
  }

  data = {
    "admin_username" = "admin"
    "admin_password" = random_password.postgres_passwords["admin"].result
    "user_username" = "user"
    "user_password" = random_password.postgres_passwords["user"].result
  }
}

resource "random_password" "postgres_passwords" {
  for_each = toset(["admin", "user"])

  length  = 10
  special = true
  upper   = true
  lower   = true
  numeric = true
}

module "postgres" {
  source = "./database"
  namespace = var.namespace
  user_passwords_secret = kubernetes_secret.postgres.metadata[0].name
}

# Run apply from this terraform directory to run this module
module "app-service-1" {
  source                           = "../app-service-1/src/main/terraform"
  container_name = var.container_name
  # Configuration, or any of these variables could be hard coded here
  configuration                    = var.configuration
  port                             = local.app_port
  additional_environment_variables = var.additional_environment_variables
  replicas                         = var.replicas
  app_name                         = local.app_name_1
  app_service_2_url                = local.app_service_2_url
  namespace                        = var.namespace
  image_pull_secret                = kubernetes_secret.docker_registry.metadata[0].name
}

module "app-service-2" {
  source                           = "../app-service-2/src/main/terraform"
  container_name = var.container_name
  # Configuration, or any of these variables could be hard coded here
  configuration                    = var.configuration
  port                             = local.app_port
  additional_environment_variables = var.additional_environment_variables
  replicas                         = var.replicas
  app_name                         = local.app_name_2
  namespace                        = var.namespace
  image_pull_secret                = kubernetes_secret.docker_registry.metadata[0].name
  jdbcUrl = module.postgres.jdbcUrl
  # hard coded
  schema = "postgres"
  username = "postgres"
  password = "postgres"
  depends_on = [module.postgres]
}

module "ingress" {
  source            = "./ingress"
  namespace         = var.namespace
  ingress_namespace = kubernetes_namespace.ingress-nginx-namespace.metadata[0].name
  ingress_paths = [
    {
      path = "/app1"
      # Because the `ingress` lives in the same namespace as the application services, it can auto resolve the full service name of
      # "${local.app_name_1}-service.${var.namespace}.svc.cluster.local" by only providing "${local.app_name_1}-service".
      # If it was in another namespace, the full service name shown above would need to be used (with a different namespace of course).
      service_name = "${local.app_name_1}-service"
      service_port = local.app_port
    }
  ]
  replicas = 1
  depends_on = [module.app-service-1]
}