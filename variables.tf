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

# Suffix to make globally-unique resource names (Key Vault / Storage Account)
# Key Vault:       "${var.project_prefix}-kv-${var.name_suffix}"
# Storage Account: lowercase, alphanumeric, 3-24 chars, no hyphens
variable "name_suffix" {
  description = "Suffix to make globally unique names for Key Vault and Storage Account"
  type        = string
  default     = "nt01"

  validation {
    condition     = can(regex("^[a-z0-9]{2,10}$", var.name_suffix))
    error_message = "name_suffix must be lowercase alphanumeric (a-z, 0-9) and reasonably short (2-10 chars)."
  }
}

# Used mainly for documentation / outputs; with az login they are not required by provider auth
variable "subscription_id" {
  description = "The Subscription ID for the Azure account"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "The Tenant ID for the Azure account"
  type        = string
  sensitive   = true
}

# Optional: only needed if you later switch back to Service Principal auth
variable "client_id" {
  description = "The Client ID (App ID) for the Azure account (optional if using az login)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "client_secret" {
  description = "The Client Secret for the Azure account (optional if using az login)"
  type        = string
  sensitive   = true
  default     = ""
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

variable "allowed_ssh_source_ip" {
  description = "Source CIDR allowed to initiate SSH connections to the VM (e.g., your public IP /32)"
  type        = string
  default     = "*"
}

# Common tags for all resources
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "CST8922-Analytics-Sandbox"
    Environment = "Development"
    Team        = "Group1"
    ManagedBy   = "Terraform"
  }
}
