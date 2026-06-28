# Picks a value based on the current workspace name
locals {
  environment = terraform.workspace
}

# Creates a file named after the environment
resource "local_file" "example" {
  filename = "${local.environment}-config.txt"
  content  = "This is the ${local.environment} environment."
}

output "current_workspace" {
  value = terraform.workspace
}
