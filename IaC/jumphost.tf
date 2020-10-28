# Create virtual machine
resource "azurerm_virtual_machine" "jumphost" {
  count                        = length(local.azs)
  name                         = format("%s-jumphost-%s-%s-%s", var.prefix, count.index, var.hex_label, terraform.workspace)
  location                     = var.specification[terraform.workspace]["region"]
  resource_group_name          = data.azurerm_resource_group.main.name
  primary_network_interface_id = azurerm_network_interface.jh_pub_nic[count.index].id
  network_interface_ids        = [azurerm_network_interface.jh_pub_nic[count.index].id, azurerm_network_interface.jh_priv_nic[count.index].id]
  vm_size                      = var.jumphost_instance_type # https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes-general
  zones                        = [element(local.azs, count.index)]

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # if this is set to false there are behaviors that will require manual intervention
  # if tainting the virtual machine
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true
  storage_os_disk {
    name              = format("%s-jumphost-%s-%s-%s", var.prefix, count.index, var.hex_label, terraform.workspace)
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = format("%s-jumphost-%s-%s-%s", var.prefix, count.index, var.hex_label, terraform.workspace)
    admin_username = "azureuser"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/azureuser/.ssh/authorized_keys"
      key_data = file(var.publickeyfile)
    }
  }

  boot_diagnostics {
    enabled     = "true"
    storage_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
  }

  tags = {
    environment = var.specification[terraform.workspace]["environment"]
    Ansible     = "jumphost"
  }
}

# Create network interface
resource "azurerm_network_interface" "jh_pub_nic" {
  count                     = length(local.azs)
  name                      = format("%s-jh-pub-nic-%s-%s-%s", var.prefix, count.index, var.hex_label, terraform.workspace)
  location                  = var.specification[terraform.workspace]["region"]
  resource_group_name       = data.azurerm_resource_group.main.name
  network_security_group_id = azurerm_network_security_group.jh_sg.id

  ip_configuration {
    primary                       = true
    name                          = format("%s-jh-pub-nic-%s-%s-%s", var.prefix, count.index, var.hex_label, terraform.workspace)
    subnet_id                     = azurerm_subnet.public[count.index].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jh_public_ip[count.index].id
  }

  tags = {
    environment = var.specification[terraform.workspace]["environment"]
  }
}

# Create network interface
resource "azurerm_network_interface" "jh_priv_nic" {
  count                     = length(local.azs)
  name                      = format("%s-jh-priv-nic-%s-%s-%s", var.prefix, count.index, var.hex_label, terraform.workspace)
  location                  = var.specification[terraform.workspace]["region"]
  resource_group_name       = data.azurerm_resource_group.main.name
  network_security_group_id = azurerm_network_security_group.jh_sg.id

  ip_configuration {
    name                          = format("%s-jh-priv-nic-%s-%s-%s", var.prefix, count.index, var.hex_label, terraform.workspace)
    subnet_id                     = azurerm_subnet.private[count.index].id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = var.specification[terraform.workspace]["environment"]
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "jh_sg" {
  name                = format("%s-jh_sg-%s-%s", var.prefix, var.hex_label, terraform.workspace)
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

# Create public IPs
resource "azurerm_public_ip" "jh_public_ip" {
  count               = length(local.azs)
  name                = format("%s-jh-%s-%s-%s", var.prefix, count.index, var.hex_label, terraform.workspace)
  location            = var.specification[terraform.workspace]["region"]
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method   = "Static"   # Static is required due to the use of the Standard sku
  sku                 = "Standard" # the Standard sku is required due to the use of availability zones
  zones               = [element(local.azs, count.index)]

  tags = {
    environment = var.specification[terraform.workspace]["environment"]
  }
}
