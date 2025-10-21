# Creates the resource group in Azure account
# "main" is the Terraform resource name

resource "azurerm_resource_group" "main" {
  name     = "${var.project_prefix}-rg"
  location = var.location
}
