locals {
  ltm_instance_count = var.specification[terraform.workspace]["ltm_instance_count"]
}

# Create F5 BIGIP VMs 
resource "azurerm_virtual_machine" "f5bigip" {
  count                        = local.ltm_instance_count
  name                         = format("%s-bigip-%s-%s-%s", var.prefix, count.index, var.hex_label, terraform.workspace)
  location                     = var.specification[terraform.workspace]["region"]
  resource_group_name          = data.azurerm_resource_group.main.name
  primary_network_interface_id = azurerm_network_interface.mgmt-nic[count.index].id
  network_interface_ids        = [azurerm_network_interface.mgmt-nic[count.index].id, azurerm_network_interface.ext-nic[count.index].id, azurerm_network_interface.int-nic[count.index].id]
  vm_size                      = var.instance_type
  zones                        = local.azs

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true


  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  #Reference to 15.1 marketplace image 
  storage_image_reference {
    publisher = "f5-networks"
    offer     = var.product
    sku       = var.image_name
    version   = var.bigip_version
  }

  storage_os_disk {
    name              = format("%s-bigip-osdisk-%s-%s-%s", var.prefix, count.index, var.hex_label, terraform.workspace)
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = "80"
  }

  os_profile {
    computer_name  = format("%s-bigip-%s-%s-%s", var.prefix, count.index, var.hex_label, terraform.workspace)
    admin_username = "azureuser"
    admin_password = var.bigip_password
    custom_data    = data.template_file.vm_onboard[count.index].rendered
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  #Reference to 15.1 marketplace image plan 
  plan {
    name      = var.image_name
    publisher = "f5-networks"
    product   = var.product
  }

  tags = {
    Name        = format("%s-bigip-%s-%s-%s", var.prefix, count.index, var.hex_label, terraform.workspace)
    environment = var.specification[terraform.workspace]["environment"]
    Ansible     = "ltm"
  }

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOF
    token=$(/usr/bin/curl -k -X POST https://${var.bigiq_license_host}:443/mgmt/shared/authn/login \
      -H "Content-Type: application/json" \
      -d "{\"username\": \"${var.bigiq_license_username}\", \"password\": \"${var.bigiq_license_password}\", \"loginProviderName\": \"tmos\"}" | jq -r ".token.token")     
    mac=${azurerm_network_interface.mgmt-nic.*.mac_address[count.index]}
    formated_mac="$${mac//-/:}"    
    /usr/bin/curl -v -k -X POST https://${var.bigiq_license_host}:443/mgmt/cm/device/tasks/licensing/pool/member-management \
      --retry 60 \
      --retry-connrefused \
      --retry-delay 120 \
      -H "Content-Type: application/json" \
      -H "X-F5-Auth-Token: '$${token}'" \
      -d "{\"licensePoolName\": \"${var.bigiq_license_licensepool}\", \"command\": \"revoke\", \"address\": \"${azurerm_network_interface.mgmt-nic.*.private_ip_address[count.index]}\", \"assignmentType\": \"UNREACHABLE\", \"macAddress\": \"$${formated_mac}\", \"hypervisor\": \"azure\"}"
    EOF
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "management_sg" {
  name                = format("%s-mgmt_sg-%s-%s", var.prefix, var.hex_label, terraform.workspace)
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

  security_rule {
    name                       = "HTTPS"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "configsync"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "1026"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }


  tags = {
    environment = var.specification[terraform.workspace]["environment"]
  }
}

# Create interfaces for the BIGIPs 
resource "azurerm_network_interface" "mgmt-nic" {
  count                     = local.ltm_instance_count
  name                      = format("%s-mgmtnic-%s-%s-%s", var.prefix, count.index, var.hex_label, terraform.workspace)
  location                  = var.specification[terraform.workspace]["region"]
  resource_group_name       = data.azurerm_resource_group.main.name
  network_security_group_id = azurerm_network_security_group.management_sg.id

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.management[count.index % length(local.azs)].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.management_public_ip[count.index].id
  }

  tags = {
    Name        = format("%s-mgmtnic-%s-%s-%s", var.prefix, count.index, var.hex_label, terraform.workspace)
    environment = var.specification[terraform.workspace]["environment"]
  }
}

# Create Application Traffic Network Security Group and rule
resource "azurerm_network_security_group" "application_sg" {
  name                = format("%s-application_sg-%s-%s", var.prefix, var.hex_label, terraform.workspace)
  location            = var.specification[terraform.workspace]["region"]
  resource_group_name = data.azurerm_resource_group.main.name

  security_rule {
    name                       = "HTTPS"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = var.specification[terraform.workspace]["environment"]
  }
}

resource "azurerm_network_interface" "ext-nic" {
  count                         = local.ltm_instance_count
  name                          = format("%s-extnic-%s-%s-%s", var.prefix, count.index, var.hex_label, terraform.workspace)
  location                      = var.specification[terraform.workspace]["region"]
  resource_group_name           = data.azurerm_resource_group.main.name
  network_security_group_id     = azurerm_network_security_group.application_sg.id
  enable_accelerated_networking = true
  enable_ip_forwarding          = true

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.public[count.index % length(local.azs)].id
    private_ip_address_allocation = "Dynamic"
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.sip_public_ip[count.index].id
  }

  ip_configuration {
    name                          = "juiceshop"
    subnet_id                     = azurerm_subnet.public[count.index % length(local.azs)].id
    private_ip_address_allocation = "Dynamic"
  }


  tags = {
    Name        = format("%s-extnic-%s-%s-%s", var.prefix, count.index, var.hex_label, terraform.workspace)
    environment = var.specification[terraform.workspace]["environment"]

  }
}

resource "azurerm_network_interface" "int-nic" {
  count                         = local.ltm_instance_count
  name                          = format("%s-intnic-%s-%s-%s", var.prefix, count.index, var.hex_label, terraform.workspace)
  location                      = var.specification[terraform.workspace]["region"]
  resource_group_name           = data.azurerm_resource_group.main.name
  network_security_group_id     = azurerm_network_security_group.management_sg.id
  enable_accelerated_networking = true
  enable_ip_forwarding          = true

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.private[count.index % length(local.azs)].id
    private_ip_address_allocation = "Dynamic"
    primary                       = true
  }

  tags = {
    Name        = format("%s-intnic-%s-%s-%s", var.prefix, count.index, var.hex_label, terraform.workspace)
    environment = var.specification[terraform.workspace]["environment"]
  }
}

# Create public IPs for BIG-IP management UI
resource "azurerm_public_ip" "management_public_ip" {
  count               = local.ltm_instance_count
  name                = format("%s-bigip-%s-%s-%s", var.prefix, count.index, var.hex_label, terraform.workspace)
  location            = var.specification[terraform.workspace]["region"]
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method   = "Static"   # Static is required due to the use of the Standard sku
  sku                 = "Standard" # the Standard sku is required due to the use of availability zones
  zones               = [element(local.azs, count.index)]

  tags = {
    environment = var.specification[terraform.workspace]["environment"]
  }
}

# Create public IPs for External Self-IP
resource "azurerm_public_ip" "sip_public_ip" {
  count               = local.ltm_instance_count
  name                = format("%s-sip-%s-%s-%s", var.prefix, count.index, var.hex_label, terraform.workspace)
  location            = var.specification[terraform.workspace]["region"]
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method   = "Static"   # Static is required due to the use of the Standard sku
  sku                 = "Standard" # the Standard sku is required due to the use of availability zones
  zones               = [element(local.azs, count.index)]

  tags = {
    environment = var.specification[terraform.workspace]["environment"]
  }
}

# Setup Onboarding scripts
data "template_file" "vm_onboard" {
  template = "${file("${path.module}/onboard.tpl")}"
  count                        = local.ltm_instance_count

  vars = {
    uname = var.admin_username
    # replace this with a reference to the secret id 
    upassword                   = var.bigip_password
    DO_URL                      = var.DO_URL
    AS3_URL                     = var.AS3_URL
    TS_URL                      = var.TS_URL
    bigip_hostname              = format("%s-bigip-%s-%s-%s.local", var.prefix, count.index, var.hex_label, terraform.workspace)
    bigiq_license_host          = var.bigiq_license_host
    bigiq_license_username      = var.bigiq_license_username
    bigiq_license_password      = var.bigiq_license_password
    bigiq_license_licensepool   = var.bigiq_license_licensepool
    bigiq_license_skuKeyword1   = var.bigiq_license_skuKeyword1
    bigiq_license_skuKeyword2   = var.bigiq_license_skuKeyword2
    bigiq_license_unitOfMeasure = var.bigiq_license_unitOfMeasure
    bigiq_hypervisor            = "azure"
    name_servers                = "168.63.129.16"
    search_domain               = "f5.com"
    ntp_servers                 = "0.pool.ntp.org"
    internal_self_ip            = azurerm_network_interface.int-nic[count.index].private_ip_address
    external_self_ip            = azurerm_network_interface.ext-nic[count.index].private_ip_address
    default_gateway_ip          = cidrhost(cidrsubnet(var.specification[terraform.workspace]["cidr"], 8, 20), 1)
    F5_MASTER_KEY               = var.f5_master_key
  }
}

