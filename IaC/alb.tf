resource "azurerm_public_ip" "alb" {
  name                = format("%s-ip-%s-%s", var.prefix, var.hex_label, terraform.workspace)
  location            = var.specification[terraform.workspace]["region"]
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "lb" {
  name                = format("%s-alb-%s-%s", var.prefix, var.hex_label, terraform.workspace)
  location            = var.specification[terraform.workspace]["region"]
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.alb.id
  }
}

resource "azurerm_lb_backend_address_pool" "pool" {
  resource_group_name = data.azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.lb.id
  name                = format("%s-pool-%s-%s", var.prefix, var.hex_label, terraform.workspace)
}

resource "azurerm_lb_probe" "lb_probe" {
  resource_group_name = data.azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "tcpProbe"
  protocol            = "tcp"
  port                = 443
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "juiceshop" {
  resource_group_name            = data.azurerm_resource_group.main.name
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = format("%s-lbrule-%s-%s", var.prefix, var.hex_label, terraform.workspace)
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = azurerm_lb_probe.lb_probe.id
  backend_address_pool_id        = azurerm_lb_backend_address_pool.pool.id
}

resource "azurerm_network_interface_backend_address_pool_association" "juiceshop" {
  count                   = local.ltm_instance_count
  network_interface_id    = azurerm_network_interface.ext-nic[count.index].id
  ip_configuration_name   = "juiceshop"
  backend_address_pool_id = azurerm_lb_backend_address_pool.pool.id
}
