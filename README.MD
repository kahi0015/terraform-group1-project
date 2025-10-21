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
