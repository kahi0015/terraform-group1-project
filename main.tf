// terraform block reference
// https://developer.hashicorp.com/terraform/language/block/terraform

terraform {
  required_version = ">= 1.0.0"

// Declare the required providers for this configuration
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0"
    }
  }
}

provider "azurerm" {
  features {}
    subscription_id = var.subscription_id
    client_id       = var.client_id
    client_secret   = var.client_secret
    tenant_id       = var.tenant_id
}

// Using the data source to get information about the current authenticated client
data "azurerm_client_config" "current" {}

// Create an Azure Key Vault to store secrets
resource "azurerm_key_vault" "main" {
  name                        = lower("${var.project_prefix}-kv")
  location                    = var.location
  resource_group_name         = azurerm_resource_group.main.name
  tenant_id                   = var.tenant_id
  sku_name                    = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
    ]
  }
}

// Create the storage account for the datasets
resource "azurerm_storage_account" "datasets" {
    name                     = lower("${var.project_prefix}datasets")
    resource_group_name      = azurerm_resource_group.main.name
    location                 = var.location
    account_tier             = "Standard"
    account_replication_type = "LRS"
    allow_nested_items_to_be_public = false
}

// Create the container for the datasets
resource "azurerm_storage_container" "data_container" {
    name                  = "data"
    storage_account_id    = azurerm_storage_account.datasets.id
    container_access_type = "private"
}

// Create virtual network
resource "azurerm_virtual_network" "main" {
    name                = lower("${var.project_prefix}-vnet")
    address_space       = ["10.0.0.0/16"]
    location            = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
}

// Create subnet
resource "azurerm_subnet" "main" {
    name                 = lower("${var.project_prefix}-subnet")
    resource_group_name  = azurerm_resource_group.main.name
    virtual_network_name = azurerm_virtual_network.main.name
    address_prefixes     = ["10.0.1.0/24"]
    default_outbound_access_enabled = true # needed to reach Azure Storage and MySQL
}

// Create internal network interface card (NIC)
resource "azurerm_network_interface" "internal_nic" {
    name                = lower("${var.project_prefix}-nic")
    location            = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name

    ip_configuration {
        name                          = "internal"
        subnet_id                     = azurerm_subnet.main.id
        private_ip_address_allocation = "Dynamic"
        private_ip_address_version = "IPv4"
    }

    ip_forwarding_enabled = false
}

// Create a virtual machine
resource "azurerm_linux_virtual_machine" "main" {
    name                = lower("${var.project_prefix}-vm")
    resource_group_name = azurerm_resource_group.main.name
    location            = azurerm_resource_group.main.location
    size                = "Standard_B2s"
    admin_username      = "group1.admin"
    admin_password      = var.admin_password
    disable_password_authentication = false

    network_interface_ids = [
        azurerm_network_interface.internal_nic.id,
    ]

    os_disk {
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
    }

  provision_vm_agent = true
  extensions_time_budget = "PT1H"
  priority = "Regular"
}
