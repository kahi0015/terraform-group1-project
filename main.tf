// Terraform block reference
// https://developer.hashicorp.com/terraform/language/block/terraform

terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# IMPORTANT:
# Use Azure CLI authentication for local runs (az login).
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

data "azurerm_client_config" "current" {}

######## RESOURCE GROUP ################################
resource "azurerm_resource_group" "main" {
  name     = "${var.project_prefix}-rg"
  location = var.location
}

######## LOG ANALYTICS WORKSPACE #####################################
resource "azurerm_log_analytics_workspace" "law" {
  name                = lower("${var.project_prefix}-law")
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

######## KEY VAULT #####################################
resource "azurerm_key_vault" "main" {
  name                = lower("${var.project_prefix}-kv-${var.name_suffix}")
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = var.tenant_id
  sku_name            = "standard"

  access_policy {
    tenant_id = var.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Recover",
      "Backup",
      "Restore",
      "Purge",
    ]
  }
}

######## KEY VAULT SECRETS #####################################
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
  name                = lower("${var.project_prefix}-vnet")
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]
}

######## SUBNETS #####################################
resource "azurerm_subnet" "main" {
  name                 = lower("${var.project_prefix}-subnet")
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]

  default_outbound_access_enabled   = true
  private_endpoint_network_policies = "Disabled"

}

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
    source_address_prefix      = var.allowed_ssh_source_ip
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg" {
  subnet_id                 = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

######## STORAGE ACCOUNT #####################################
resource "azurerm_storage_account" "datasets" {
  name                            = lower("cst8922g1ds${var.name_suffix}")
  resource_group_name             = azurerm_resource_group.main.name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false

  min_tls_version            = "TLS1_2"
  https_traffic_only_enabled = true
}

resource "azurerm_storage_container" "raw_data" {
  name                  = "raw"
  container_access_type = "private"
  storage_account_name  = azurerm_storage_account.datasets.name
}

resource "azurerm_storage_container" "processed_data" {
  name                  = "processed"
  container_access_type = "private"
  storage_account_name  = azurerm_storage_account.datasets.name
}

resource "azurerm_storage_container" "reports" {
  name                  = "reports"
  container_access_type = "private"
  storage_account_name  = azurerm_storage_account.datasets.name
}

resource "azurerm_storage_management_policy" "datasets_lifecycle" {
  storage_account_id = azurerm_storage_account.datasets.id

  rule {
    name    = "analytics-data-lifecycle"
    enabled = true

    filters {
      prefix_match = ["raw/", "processed/", "reports/"]
      blob_types   = ["blockBlob"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than    = 30
        tier_to_archive_after_days_since_modification_greater_than = 90
        delete_after_days_since_modification_greater_than          = 365
      }
    }
  }
}

######## PRIVATE DNS ZONE (STORAGE BLOB) #####################################
resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob_link" {
  name                  = lower("${var.project_prefix}-blob-vnet-link")
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
}

resource "azurerm_private_endpoint" "storage_blob_pe" {
  name                = lower("${var.project_prefix}-st-blob-pe")
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.main.id

  private_service_connection {
    name                           = lower("${var.project_prefix}-st-blob-psc")
    private_connection_resource_id = azurerm_storage_account.datasets.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "blob-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.blob_link,
    azurerm_storage_account.datasets
  ]
}

######## PRIVATE DNS ZONE (MYSQL) #####################################
resource "azurerm_private_dns_zone" "mysql" {
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name
}

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

  administrator_login    = azurerm_key_vault_secret.db_admin_username.value
  administrator_password = azurerm_key_vault_secret.db_admin_password.value

  delegated_subnet_id          = azurerm_subnet.mysql.id
  private_dns_zone_id          = azurerm_private_dns_zone.mysql.id
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  depends_on = [azurerm_private_dns_zone_virtual_network_link.mysql]

  lifecycle {
    ignore_changes = [zone]
  }
}

resource "azurerm_mysql_flexible_database" "analytics_db" {
  name                = "analyticsdb"
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_mysql_flexible_server.main.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

######## NETWORK INTERFACE #####################################
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
}

######## VIRTUAL MACHINE #####################################
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
  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.main.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
}

######## DIAGNOSTIC SETTINGS #####################################
resource "azurerm_monitor_diagnostic_setting" "vm_diag" {
  name                       = lower("${var.project_prefix}-vm-diag")
  target_resource_id         = azurerm_linux_virtual_machine.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
