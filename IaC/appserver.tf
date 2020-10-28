locals {
  application_count = var.specification[terraform.workspace]["application_count"]
}

# Create virtual machine
resource "azurerm_virtual_machine" "appserver" {
  count                 = length(local.azs) * local.application_count # all applications are duplicated across availability zones
  name                  = format("%s-appserver-%s-%s-%s", var.prefix, count.index, var.hex_label, terraform.workspace)
  location              = var.specification[terraform.workspace]["region"]
  resource_group_name   = data.azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.app_nic[count.index].id]
  vm_size               = var.appsvr_instance_type
  zones                 = [element(local.azs, count.index)]

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # if this is set to false there are behaviors that will require manual intervention
  # if tainting the virtual machine
  delete_os_disk_on_termination = true


  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_os_disk {
    name              = format("%s-appserver-%s-%s-%s", var.prefix, count.index, var.hex_label, terraform.workspace)
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
#Uncomment for private VM image
  #storage_image_reference {
  #  id = var.app_image_id
  #}
#Comment for private VM image. 
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  os_profile {
    computer_name  = format("%s-appserver-%s-%s-%s", var.prefix, count.index, var.hex_label, terraform.workspace)
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
    Ansible     = "nginx"
  }
}

# Create network interface
resource "azurerm_network_interface" "app_nic" {
  count                     = length(local.azs) * local.application_count
  name                      = format("%s-app-nic-%s-%s-%s", var.prefix, count.index, var.hex_label, terraform.workspace)
  location                  = var.specification[terraform.workspace]["region"]
  resource_group_name       = data.azurerm_resource_group.main.name
  network_security_group_id = azurerm_network_security_group.app_sg.id

  ip_configuration {
    name                          = format("%s-app-nic-%s-%s-%s", var.prefix, count.index, var.hex_label, terraform.workspace)
    subnet_id                     = azurerm_subnet.private[count.index % length(local.azs)].id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = var.specification[terraform.workspace]["environment"]
    application = "juiceshop"
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "app_sg" {
  name                = format("%s-app_sg-%s-%s", var.prefix, var.hex_label, terraform.workspace)
  location            = var.specification[terraform.workspace]["region"]
  resource_group_name = data.azurerm_resource_group.main.name

  # extend the set of security rules to address the needs of
  # the applications deployed on the application server
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = local.cidr # only allow traffic from within the virtual network
    destination_address_prefix = "*"
  }

  tags = {
    environment = var.specification[terraform.workspace]["environment"]
  }
}
