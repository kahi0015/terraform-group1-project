# Terraform Azure Project Setup – Service Principal Steps

## 1. App Registration

- Created the app registration in the Azure Portal for `group1-app`.

## 2. Service Principal

- Ensured that the service principal was created alongside the app registration.

## 3. Role Assignment

- Assigned the **Contributor** role to the service principal at the **subscription level** in Azure Portal, by selecting members as `group1-app`

## 4. Credential Verification

- Verified that the following credentials are defined under the `provider "azurerm"` block and match the app registration:
  - `client_id`
  - `client_secret`
  - `tenant_id`
  - `subscription_id`

# 5. Secrets Handling

- Must create secrets.tfvars file containing the following variables (also defined in variables.tf ):
  subscription_id = ""
  client_id = ""
  client_secret = ""
  tenant_id = ""
  db_admin_username = ""
  db_admin_password = ""
  vm_admin_password = ""

# 6. To consider the secrets file, run with -var-file="secrets.tfvars":

```bash
  terraform plan -var-file="secrets.tfvars"
  terraform apply -var-file="secrets.tfvars"
```

##### For next phase

# 7. Run scp to copy the script (VM is not publicly accessible - Set temporary public ip first)

- Go to VM -> Networking -> Network Settings -> Network Interface/IP Configurations -> internal (Primary) -> Associate public IP address ->
  Create a public IP address (Standard)

- In Network security: group cst8922group1-nsg -> SSH-Allow -> Source (My IP Address)

```bash
  scp ./scripts/sandboxdb.sql group1admin@<vm_public_ip>:/home/group1admin/
```

# 8. Run the MySQL script (TODO - TOTEST)

```
  mysql -h <mysql_server_private_fqdn (Endpoint)> -u mysqladmin -p<db_password> < /home/group1admin/sandboxdb.sql
```
