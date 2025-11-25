# Sets global variables for this Terraform project

variable "app_name" {
  description = "The name of the application"
  type        = string
  default     = "group1-app"
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
  default     = "Canada Central"
}

variable "project_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "cst8922group1"
}

variable "subscription_id" {
  description = "The Subscription ID for the Azure account"
  type        = string
  sensitive   = true
}

variable "client_id" {
  description = "The Client ID for the Azure account"
  type        = string
  sensitive   = true
}

variable "client_secret" {
  description = "The Client Secret for the Azure account"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "The Tenant ID for the Azure account"
  type        = string
  sensitive   = true
}

variable "db_admin_username" {
  description = "Admin username for MySQL"
  type        = string
}

variable "db_admin_password" {
  description = "Admin password for MySQL"
  type        = string
  sensitive   = true
}

variable "vm_admin_password" {
  description = "Admin password for the Linux VM"
  type        = string
  sensitive   = true
}

# Controls which source CIDR or wildcard is allowed to initiate SSH connections to the VM
variable "allowed_ssh_source_ip" {
  description = "Source CIDR or wildcard that is allowed to initiate SSH connections to the VM"
  type        = string
  default     = "*"
}
