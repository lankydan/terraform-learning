locals {
  app_config_location = "/app/config"
  app_config_volume   = "config-volume"
  config = {
    port = var.port
    app_service_2_url = var.app_service_2_url
  }
}