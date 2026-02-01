locals {
  app_config_location = "/app/config"
  app_config_volume   = "config-volume"
  config = {
    port = var.port
    database = {
      jdbcUrl = var.jdbcUrl
      schema = var.schema
      username = var.username
      password = var.password
    }
  }
}