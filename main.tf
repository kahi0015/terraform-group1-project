// terraform block reference
// https://developer.hashicorp.com/terraform/language/block/terraform

terraform {
  required_version = ">= 1.0"

  // Declaring the required providers for this configuration
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}

  # Provider authentication via Key Vault secrets
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

// Using the data source to get information about the current authenticated client
data "azurerm_client_config" "current" {}

######## RESOURCE GROUP ################################
resource "azurerm_resource_group" "main" {
  name     = "${var.project_prefix}-rg"
  location = var.location
}

######## Log Analytics Workspace #####################################
resource "azurerm_log_analytics_workspace" "law" {
  name                = lower("${var.project_prefix}-law")
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

######### KEY VAULT RESOURCE #####################################
resource "azurerm_key_vault" "main" {
  name                = lower("${var.project_prefix}-kv")
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = var.tenant_id
  sku_name            = "standard"

  # Allow Terraform to manage secrets
  access_policy {
    tenant_id = var.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
    ]
  }
}

######### KEY VAULT SECRETS #####################################
resource "azurerm_key_vault_secret" "db_admin_username" {
  name         = "db-admin-username"
  value        = var.db_admin_username
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_key_vault_secret" "db_admin_password" {
  name         = "db-admin-password"
  value        = var.db_admin_password
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_key_vault_secret" "vm_admin_password" {
  name         = "vm-admin-password"
  value        = var.vm_admin_password
  key_vault_id = azurerm_key_vault.main.id
}

######## VIRTUAL NETWORK #####################################
resource "azurerm_virtual_network" "main" {
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  name                = lower("${var.project_prefix}-vnet")
  resource_group_name = azurerm_resource_group.main.name
}

// Manages the subnet
resource "azurerm_subnet" "main" {
  address_prefixes                = ["10.0.1.0/24"]
  name                            = lower("${var.project_prefix}-subnet")
  resource_group_name             = azurerm_resource_group.main.name
  virtual_network_name            = azurerm_virtual_network.main.name
  default_outbound_access_enabled = true # needed to reach Azure Storage and MySQL
}

// Manages the subnet for MySQL Flexible Server with delegation
resource "azurerm_subnet" "mysql" {
  name                 = lower("${var.project_prefix}-mysql-subnet")
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]

  delegation {
    name = "mysqlDelegation"
    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

######## NETWORK SECURITY GROUP (NSG) #####################################
resource "azurerm_network_security_group" "vm_nsg" {
  name                = "${var.project_prefix}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "SSH-Allow"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"  
    destination_port_range     = "22"
    source_address_prefix      = "*" # Allowed from any source - TODO: restrict in production to specific IPs
    destination_address_prefix = "*"
  }
}


// Associate NSG with subnet
resource "azurerm_subnet_network_security_group_association" "subnet_nsg" {
  subnet_id                 = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

######## STORAGE ACCOUNT #####################################
resource "azurerm_storage_account" "datasets" {
  name                            = lower("${var.project_prefix}datasets")
  resource_group_name             = azurerm_resource_group.main.name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
}

// Create the container for the datasets
resource "azurerm_storage_container" "data_container" {
  name                  = "data"
  container_access_type = "private"
  storage_account_name  = azurerm_storage_account.datasets.name
}

######## PRIVATE DNS ZONE #####################################
// Private DNS zone for MySQL
resource "azurerm_private_dns_zone" "mysql" {
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name
}

// Linking private DNS zone to virtual network
resource "azurerm_private_dns_zone_virtual_network_link" "mysql" {
  name                  = lower("${var.project_prefix}-vnet-link")
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.mysql.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false

  depends_on = [
    azurerm_private_dns_zone.mysql,
    azurerm_subnet.mysql
  ]
}

######## MYSQL FLEXIBLE SERVER #####################################
resource "azurerm_mysql_flexible_server" "main" {
  name                = lower("${var.project_prefix}-mysql")
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku_name            = "B_Standard_B1ms"

  administrator_login          = azurerm_key_vault_secret.db_admin_username.value
  administrator_password       = azurerm_key_vault_secret.db_admin_password.value
  delegated_subnet_id          = azurerm_subnet.mysql.id # MySQL delegated subnet enforces private access
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  private_dns_zone_id          = azurerm_private_dns_zone.mysql.id

  depends_on = [azurerm_private_dns_zone_virtual_network_link.mysql]

  lifecycle {
    ignore_changes = [zone]
  }
}

### MYSQL DATABASE 
resource "azurerm_mysql_flexible_database" "analytics_db" {
  name                = "analyticsdb"
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_mysql_flexible_server.main.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

### VIRTUAL MACHINE 
// Create internal network interface card (NIC)
resource "azurerm_network_interface" "internal_nic" {
  name                = lower("${var.project_prefix}-nic")
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    private_ip_address_version    = "IPv4"
  }

  # ip_forwarding_enabled = false
}

// Create a virtual machine
resource "azurerm_linux_virtual_machine" "main" {
  name                            = lower("${var.project_prefix}-vm")
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = "Standard_B2s"
  admin_username                  = "group1admin"
  admin_password                  = azurerm_key_vault_secret.vm_admin_password.value
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
}

######## VM EXTENSION - AZURE MONITOR AGENT (AMA) #####################################
resource "azurerm_virtual_machine_extension" "ama" {
  name                 = "AzureMonitorLinuxAgent"
  virtual_machine_id   = azurerm_linux_virtual_machine.vm.id
  publisher            = "Microsoft.Azure.Monitor"
  type                 = "AzureMonitorLinuxAgent"
  type_handler_version = "1.0"
  auto_upgrade_minor_version = true
}


######## Diagnostic Settings #####################################
resource "azurerm_monitor_diagnostic_setting" "vm_diag" {
  name                       = lower("${var.project_prefix}-vm-diag")
  target_resource_id         = azurerm_linux_virtual_machine.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  metric {
    category = "AllMetrics"
    enabled  = true
  }
  }
