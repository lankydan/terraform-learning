locals {
  app_name_1        = "my-app-1"
  app_name_2        = "my-app-2"
  app_port          = 8080
  app_service_2_url = "${local.app_name_2}-service.${var.namespace}.svc.cluster.local:${local.app_port}"
}