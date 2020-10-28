locals {
  cidr = var.specification[terraform.workspace]["cidr"]
  azs  = var.specification[terraform.workspace]["azs"]
}

# Create virtual network
resource "azurerm_virtual_network" "main" {
  name                = format("%s-vnet-%s-%s", var.prefix, var.hex_label, terraform.workspace)
  address_space       = [local.cidr]
  location            = var.specification[terraform.workspace]["region"]
  resource_group_name = data.azurerm_resource_group.main.name

  tags = {
    environment = var.specification[terraform.workspace]["environment"]
  }
}

# Create management subnet
resource "azurerm_subnet" "management" {
  count                = length(local.azs)
  name                 = format("%s-managementsubnet-%s-%s", var.prefix, count.index, var.hex_label)
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  # address prefix 10.1x.0.0/24
  address_prefix = cidrsubnet(cidrsubnet(local.cidr, 8, 10 + count.index), 8, 0)
}
# Create public/external subnet
resource "azurerm_subnet" "public" {
  count                = length(local.azs)
  name                 = format("%s-publicsubnet-%s-%s", var.prefix, count.index, var.hex_label)
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  # address prefix 10.2x.0.0/24
  address_prefix = cidrsubnet(cidrsubnet(local.cidr, 8, 20 + count.index), 8, 0)
}
# Create private/internal subnet
resource "azurerm_subnet" "private" {
  count                = length(local.azs)
  name                 = format("%s-privatesubnet-%s-%s", var.prefix, count.index, var.hex_label)
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  # address prefix 10.3x.0.0/24
  address_prefix = cidrsubnet(cidrsubnet(local.cidr, 8, 30 + count.index), 8, 0)
}
