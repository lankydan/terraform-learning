# Provider can only exist in the top level terraform, so it has been moved here from `../src/main/terraform`.
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "docker-desktop"
}

# Run apply from this terraform directory to run this module
module "my-app" {
  source = "../src/main/terraform"
  container_name = var.container_name
  # Configuration, or any of these variables could be hard coded here
  configuration = var.configuration
  my_variable = var.my_variable
  additional_environment_variables = var.additional_environment_variables
}