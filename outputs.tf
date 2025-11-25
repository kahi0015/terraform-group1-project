output "mysql_fqdn" {
  value       = azurerm_mysql_flexible_server.main.fqdn
  description = "FQDN of the MySQL Flexible Server"
}

output "vm_private_ip" {
  value       = azurerm_network_interface.internal_nic.private_ip_address
  description = "Private IP of the Linux VM"
}

output "key_vault_name" {
  value       = azurerm_key_vault.main.name
  description = "Name of the Key Vault storing secrets"
}

output "storage_account_name" {
  value       = azurerm_storage_account.datasets.name
  description = "Name of the Storage Account"
}

output "storage_container_name" {
  value       = azurerm_storage_container.data_container.name
  description = "Name of the Storage Container for datasets"
}

// Output for the dedicated analytics database created on the MySQL Flexible Server
output "mysql_database_name" {
  value       = azurerm_mysql_flexible_database.analytics_db.name
  description = "Name of the MySQL analytics database used in the sandbox"
}
