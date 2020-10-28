output "workspace" {
  value = terraform.workspace
}

output "hex_label" {
  value = var.hex_label
}

output "bigip_mgmt_public_ips" {
  value = azurerm_public_ip.management_public_ip[*].ip_address
}

output "bigip_mgmt_port" {
  value = "443"
}

output "bigip_password" {
  value = var.bigip_password
}

output "f5_master_key" {
  value = var.f5_master_key
}

output "key_name" {
  value = var.privatekeyfile
}

output "jumphost_ip" {
  value = azurerm_public_ip.jh_public_ip[*].ip_address
}

output "juice_shop_ips" {
  value = azurerm_network_interface.app_nic[*].private_ip_address
}

output "juice_shop_alb_ip" {
  value = azurerm_public_ip.alb.ip_address
}
