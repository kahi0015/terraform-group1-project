# Terraform Azure Analytics Sandbox

[![Build Status](https://img.shields.io/badge/terraform-ready-blue)](#)
[![Azure](https://img.shields.io/badge/azure-cloud-blue)](#)

## What Is This Project?

This project is a fully automated **Azure analytics sandbox** built using **Terraform**.
It lets students and developers quickly deploy:

* A Linux VM for analytics work
* A MySQL Flexible Server database
* A Storage Account and container for datasets
* A secure Virtual Network and Network Security Group
* A Key Vault to store secrets

Everything can be **created and destroyed with a single Terraform command**.

---

## Architecture Overview

Terraform deploys the following Azure resources:

| Component                   | Description                                       |
| --------------------------- | ------------------------------------------------- |
| Resource Group              | Container for all resources                       |
| Virtual Network & Subnet    | Secure network for VM and database                |
| Ubuntu Virtual Machine      | Analytics compute node (Python, SQL tools, etc.)  |
| Storage Account + Container | Stores raw and processed datasets                 |
| MySQL Flexible Server       | Private, VNet-integrated analytics database       |
| Azure Key Vault             | Stores secrets (credentials, passwords, etc.)     |
| Network Security Group      | Controls inbound/outbound traffic, especially SSH |
| Temporary Public IP         | Used only for SSH and testing                     |

---

## Secrets Setup (`secrets.tfvars`)

Before deploying the Terraform environment, you must create a local file named:

```
secrets.tfvars
```

Add the following values into the file:

```hcl
subscription_id        = ""
client_id              = ""
client_secret          = ""
tenant_id              = ""
db_admin_username      = ""
db_admin_password      = ""
vm_admin_password      = ""
allowed_ssh_source_ip  = ""
```

---

### Notes

* Do not commit `secrets.tfvars` to GitHub
* Terraform commands **must** include this file using `-var-file="secrets.tfvars"`.
* The Service Principal values come from your Azure AD App Registration
* For local demos, Azure CLI authentication (`az login`) can be used if the environment is already authenticated.

---

### Required Terraform Commands

```bash
terraform plan -var-file="secrets.tfvars"
terraform apply -var-file="secrets.tfvars"
terraform destroy -var-file="secrets.tfvars"
```

---

## Deployment Steps

Follow the steps below to deploy the complete Azure Analytics Sandbox using Terraform.

---

### **1. Login to Azure**

Before running Terraform, login to Azure using the Azure CLI:

* Go to VM -> Networking -> Network Settings -> Network Interface/IP Configurations -> internal (Primary) -> Associate public IP address ->
  Create a public IP address (Standard)

* In Network security: group cst8922group1-nsg -> SSH-Allow -> Source (My IP Address)

```bash
az login
```

---

### **2. Initialize Terraform**

Set up Terraform’s working directory:

```bash
terraform init
```

---

### **3. Validate Terraform Configuration**

Validate all `.tf` files to make sure there are no errors:

```bash
terraform validate
```

---

### **4. Preview the Deployment Plan**

Generate an execution plan that shows which Azure resources will be created:

```bash
terraform plan -var-file="secrets.tfvars"
```

---

### **5. Apply the Deployment**

Create the full Azure environment:

```bash
terraform apply -var-file="secrets.tfvars"
```

Type `yes` when prompted.

---

### **6. View Terraform Outputs**

After deployment completes, view main resource values:

```bash
terraform output
```

---

### **7. Destroy the Environment**

When finished with the sandbox, remove all resources:

```bash
terraform destroy -var-file="secrets.tfvars"
```

Confirm with `yes` when prompted.

---

### Notes

* `secrets.tfvars` must exist for deployment.
* Ensure the Service Principal credentials inside the file are correct.

---

## CI/CD Pipeline

The project includes a GitHub Actions workflow for continuous integration:

**Location:** `.github/workflows/terraform-ci.yml`

**Triggers:**

* Push to `main` or `develop` branches
* Pull requests to `main` branch

**Pipeline Steps:**

1. Checkout repository code
2. Setup Terraform (version 1.0+)
3. Format check (`terraform fmt -check -recursive`)
4. Initialize Terraform (`terraform init`)
5. Validate configuration (`terraform validate`)

**Benefits:**

* Ensures code formatting consistency
* Catches syntax errors before deployment
* Prevents merging broken Terraform configurations

---

## Service Principal Setup

A Service Principal is required for Terraform authentication.

Full step-by-step instructions can be found in:

```
service-principal-setup.md
```

This includes:

* Creating the App Registration
* Generating `client_id` and `client_secret`
* Assigning the Contributor role
* Validating Terraform provider configuration

---

## Features Implemented

### Completed Features as of Part 3

* Creation of Resource Group
* Virtual Network and Subnet
* Network Security Group with SSH rule
* Ubuntu Linux Virtual Machine
* Temporary Public IP Assignment
* Azure Storage Account and Container
* Azure Database for MySQL Flexible Server (private VNet integration)
* Azure Key Vault for secret management
* Terraform outputs (database name, resource IDs, etc.)
* Configurable SSH source IP variable (`allowed_ssh_source_ip`)
* SQL initialization workflow (upload & run schema file)
* Validation and debugging improvements

### Completed Features as of Part 4

* Creation of Resource Group
* Virtual Network and Subnet
* Network Security Group with SSH rule
* Ubuntu Linux Virtual Machine
* Temporary Public IP Assignment
* Azure Storage Account with structured containers (raw, processed, reports)
* Azure Database for MySQL Flexible Server (private VNet integration)
* Azure Key Vault for secret management
* Terraform outputs (database name, resource IDs, etc.)
* Configurable SSH source IP variable (`allowed_ssh_source_ip`)
* SQL initialization workflow (upload & run schema file)
* Validation and debugging improvements
* **CI/CD Pipeline** - GitHub Actions for Terraform format and validation
* **Structured Data Containers** - Separate containers for analytics workflow stages
* **Lifecycle Policies** - Automatic data tier management and retention (30/90/365 days)
* **Log Analytics Workspace** - Centralized logging and monitoring (30-day retention)
* **Storage Private Endpoint + Private DNS (Blob)** - Storage access is routed through Private Link using `privatelink.blob.core.windows.net`

---

### Components Dependency Order (Part 4 - Continued here)

The components must follow the below order in the configuration file:

* Resource Group
* Log Analytics Workspace
* Key Vault
* Key Vault Secrets
* Virtual Network (VNet)
* Subnet (general)
* Subnet (MySQL delegated)
* Network Security Group (NSG)
* Private DNS Zone
* Storage Account
* Storage Container
* MySQL Server
* MySQL Database
* Network Interface (NIC)
* Virtual Machine (VM)
* VM Extension - Azure Monitor Agent (AMA)
* Diagnostic Settings

## Team - Group 1

* Mohamad Kahil
* Bobby Lubberman
* Nezihe Tekin
* Adris Azimi

---

## References

Documentation links relevant to this project:

* Terraform Documentation
  [https://developer.hashicorp.com/terraform/docs](https://developer.hashicorp.com/terraform/docs)

* AzureRM Terraform Provider
  [https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
