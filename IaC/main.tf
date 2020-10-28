# Configure the Microsoft Azure Provider
provider "azurerm" {
  version = "~> 1.43"
}

terraform {
  backend "azurerm" {}
}

# Get resource group information
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
  name                     = substr(format("%s%sdsa%s", var.prefix, var.hex_label, var.specification[terraform.workspace]["environment"]), 0, 24)
  resource_group_name      = var.resource_group_name
  location                 = var.specification[terraform.workspace]["region"]
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = var.specification[terraform.workspace]["environment"]
  }
}


# Create Network Security Group and rule
resource "azurerm_network_security_group" "securitygroup" {
  name                = format("%s-securitygroup-%s-%s", var.prefix, var.hex_label, terraform.workspace)
  location            = var.specification[terraform.workspace]["region"]
  resource_group_name = data.azurerm_resource_group.main.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = var.specification[terraform.workspace]["environment"]
  }
}
