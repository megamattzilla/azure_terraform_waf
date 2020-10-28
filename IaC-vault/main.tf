# file: IaC-vault/main.tf

# Configure the Microsoft Azure Provider
provider "azurerm" {
  version = "~> 1.44"
}

terraform {
  backend "azurerm" {}
}

#
# Create random password for BIG-IP
#
resource "random_password" "password" {
  length           = 22
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  special          = false
}

# Create Service Principal for Ansible and BIG-IP

## Get information from the current client
data "azurerm_client_config" "current" {}

## Create the AD Application
resource "azuread_application" "app" {
  name = format("%s-app", var.prefix)
}

## Create the Service Principal 
resource "azuread_service_principal" "app" {
  application_id = azuread_application.app.application_id
}

## Create a random password for the service principal
resource "random_password" "sp_password" {
  length           = 32
  special          = true
  override_special = "-"
}

## Get the Azure Subscription ID
data "azurerm_subscription" "primary" {}

## Create the Role Assignment
resource "azurerm_role_assignment" "example" {
  scope = format("/subscriptions/%s/resourceGroups/%s",
  data.azurerm_subscription.primary.subscription_id, var.resource_group_name)
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.app.id
}

## Create Service Principal password
resource "azuread_service_principal_password" "app" {
  end_date             = "2299-12-30T23:00:00Z" # Forever
  service_principal_id = azuread_service_principal.app.id
  value                = random_password.sp_password.result
}

## Create the Key Vault
resource "azurerm_key_vault" "vault" {
  name                = format("kv%s", var.prefix)
  location            = var.region
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name = "premium"

  access_policy {
    tenant_id = data.azurerm_subscription.primary.tenant_id
    object_id = azuread_service_principal.app.id

    key_permissions = [
      "create",
      "get",
      "list",
      "delete"
    ]

    secret_permissions = [
      "set",
      "get",
      "delete",
      "list",
    ]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "create",
      "get",
      "list",
      "delete"
    ]

    secret_permissions = [
      "set",
      "get",
      "delete",
      "list",
    ]
  }

  tags = {
    environment = var.region
    Ansible     = "vault"
  }
}

## Create the Key Vault Secret for BIG-IP Password
resource "azurerm_key_vault_secret" "bigip-password" {
  name         = "bigip-password"
  value        = random_password.password.result
  key_vault_id = azurerm_key_vault.vault.id

  tags = {
    environment = var.prefix
    Ansible     = "secret"
  }
}

## Create the Key Vault Secret for Service Principal 
resource "azurerm_key_vault_secret" "subscription_id" {
  name         = "subscription-id"
  value        = data.azurerm_subscription.primary.subscription_id
  key_vault_id = azurerm_key_vault.vault.id

  tags = {
    environment = var.prefix
    Ansible     = "secret"
  }
}
resource "azurerm_key_vault_secret" "service_principal_id" {
  name         = "service-principal-id"
  value        = azuread_service_principal.app.application_id
  key_vault_id = azurerm_key_vault.vault.id

  tags = {
    environment = var.prefix
    Ansible     = "secret"
  }
}
resource "azurerm_key_vault_secret" "service_principal_password" {
  name         = "service-principal-password"
  value        = random_password.sp_password.result
  key_vault_id = azurerm_key_vault.vault.id

  tags = {
    environment = var.prefix
    Ansible     = "secret"
  }
}
resource "azurerm_key_vault_secret" "tenant_id" {
  name         = "tenant-id"
  value        = data.azurerm_subscription.primary.tenant_id
  key_vault_id = azurerm_key_vault.vault.id

  tags = {
    environment = var.prefix
    Ansible     = "secret"
  }
}

## Create the Key Vault Secret for BIG-IQ Password
resource "azurerm_key_vault_secret" "bigiq" {
  name         = format("bigiq-password")
  value        = var.bigiq_password
  key_vault_id = azurerm_key_vault.vault.id

  tags = {
    environment = var.prefix
    Ansible     = "secret"
  }
}

## Create the Key Vault Secret for BIG-IP Master Key
resource "azurerm_key_vault_secret" "master-key" {
  name         = format("master-key")
  value        = var.bigip_master_key
  key_vault_id = azurerm_key_vault.vault.id

  tags = {
    environment = var.prefix
    Ansible     = "secret"
  }
}

# Create SSH key files
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "private" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = format("%s/%s", path.module, var.ssh_key_name)
  file_permission = "0600"
}

resource "local_file" "public" {
  content         = tls_private_key.ssh.public_key_openssh
  filename        = format("%s/%s.pub", path.module, var.ssh_key_name)
  file_permission = "0600"
}
