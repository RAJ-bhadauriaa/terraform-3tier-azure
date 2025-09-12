# rg
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = var.tags
}

resource "azurerm_subnet" "web" {
  name                 = "subnet-web"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_web_prefix]
}

resource "azurerm_subnet" "app" {
  name                 = "subnet-app"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_app_prefix]

  depends_on = [azurerm_virtual_network.vnet]
}

resource "azurerm_subnet" "db" {
  name                 = "subnet-db"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_db_prefix]
}

############################
# Network Security Groups
############################

resource "azurerm_network_security_group" "nsg_web" {
  name                = "nsg-web"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Web-To-App-Outbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = var.subnet_app_prefix
  }

  tags = var.tags
}

resource "azurerm_network_security_group" "nsg_app" {
  name                = "nsg-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-Web-To-App"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = var.subnet_web_prefix
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }

  security_rule {
    name                       = "Allow-App-To-DB-Outbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = var.subnet_db_prefix
    destination_port_range     = "*"
  }

  tags = var.tags
}

resource "azurerm_network_security_group" "nsg_db" {
  name                = "nsg-db"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-App-To-DB-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = var.subnet_app_prefix
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "1433"  # adjust if using different DB port
  }

  security_rule {
    name                       = "Deny-Web-To-DB"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_address_prefix      = var.subnet_web_prefix
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }

  tags = var.tags
}

############################
# Wait a little so Azure stabilizes (optional)
############################

resource "time_sleep" "wait_30_seconds" {
  create_duration = "30s"

  depends_on = [
    azurerm_subnet.web,
    azurerm_subnet.app,
    azurerm_subnet.db,
    azurerm_network_security_group.nsg_web,
    azurerm_network_security_group.nsg_app,
    azurerm_network_security_group.nsg_db
  ]
}

############################
# NSG Associations
############################

resource "azurerm_subnet_network_security_group_association" "web_nsg_assoc" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.nsg_web.id

  depends_on = [
    time_sleep.wait_30_seconds
  ]
}

resource "azurerm_subnet_network_security_group_association" "app_nsg_assoc" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.nsg_app.id

  depends_on = [
    time_sleep.wait_30_seconds,
    azurerm_subnet_network_security_group_association.web_nsg_assoc
  ]
}

resource "azurerm_subnet_network_security_group_association" "db_nsg_assoc" {
  subnet_id                 = azurerm_subnet.db.id
  network_security_group_id = azurerm_network_security_group.nsg_db.id

  depends_on = [
    time_sleep.wait_30_seconds,
    azurerm_subnet_network_security_group_association.app_nsg_assoc
  ]
}

############################
# Web Tier: Public IP, NIC, VM
############################

resource "azurerm_public_ip" "web_public_ip" {
  name                = var.web_public_ip_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

resource "azurerm_network_interface" "web_nic" {
  name                = "web-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web_public_ip.id
  }

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "web_vm" {
  name                = "web-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.web_vm_size
  admin_username      = var.admin_username

  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.web_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "20_04-lts"
    version   = "latest"
  }

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  custom_data = filebase64(var.custom_data_path)

  tags = var.tags

  depends_on = [azurerm_subnet_network_security_group_association.web_nsg_assoc]
}

############################
# App Tier: NIC + VM
############################

resource "azurerm_network_interface" "app_nic" {
  name                = "app-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "app_vm" {
  name                = "app-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.app_vm_size
  admin_username      = var.admin_username

  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.app_nic.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "20_04-lts"
    version   = "latest"
  }

  tags = var.tags

  depends_on = [azurerm_subnet_network_security_group_association.app_nsg_assoc]
}

############################
# DB Tier: NIC + VM
############################

resource "azurerm_network_interface" "db_nic" {
  name                = "db-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.db.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "db_vm" {
  name                = "db-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.db_vm_size
  admin_username      = var.admin_username

  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.db_nic.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "20_04-lts"
    version   = "latest"
  }

  tags = var.tags

  depends_on = [azurerm_subnet_network_security_group_association.db_nsg_assoc]
}

############################
# Public Load Balancer for Web Tier
############################

resource "azurerm_public_ip" "web_lb_public_ip" {
  name                = var.web_lb_public_ip_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

resource "azurerm_lb" "web_lb" {
  name                = var.web_lb_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "web-lb-frontend"
    public_ip_address_id = azurerm_public_ip.web_lb_public_ip.id
  }

  tags = var.tags
}

resource "azurerm_lb_backend_address_pool" "web_backend_pool" {
  loadbalancer_id = azurerm_lb.web_lb.id
  name            = "web-backend-pool"
}

resource "azurerm_lb_probe" "web_health_probe" {
  loadbalancer_id = azurerm_lb.web_lb.id
  name            = "web-health-probe"
  protocol        = "Http"
  port            = var.web_probe_port
  request_path    = "/"
  interval_in_seconds = 15
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "web_lb_rule_http" {
  loadbalancer_id                = azurerm_lb.web_lb.id
  name                           = "web-lb-rule-http"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "web-lb-frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.web_backend_pool.id]
  probe_id                       = azurerm_lb_probe.web_health_probe.id
  disable_outbound_snat          = false
  enable_floating_ip             = false
  idle_timeout_in_minutes        = 4
}

resource "azurerm_lb_rule" "web_lb_rule_https" {
  loadbalancer_id                = azurerm_lb.web_lb.id
  name                           = "web-lb-rule-https"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "web-lb-frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.web_backend_pool.id]
  probe_id                       = azurerm_lb_probe.web_health_probe.id
  disable_outbound_snat          = false
  enable_floating_ip             = false
  idle_timeout_in_minutes        = 4
}

resource "azurerm_network_interface_backend_address_pool_association" "web_nic_lb_association" {
  network_interface_id    = azurerm_network_interface.web_nic.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.web_backend_pool.id
}

############################
# Internal Load Balancer for App Tier
############################

resource "azurerm_lb" "app_lb" {
  name                = var.app_lb_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "app-lb-frontend"
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

resource "azurerm_lb_backend_address_pool" "app_backend_pool" {
  loadbalancer_id = azurerm_lb.app_lb.id
  name            = "app-backend-pool"
}

resource "azurerm_lb_probe" "app_health_probe" {
  loadbalancer_id = azurerm_lb.app_lb.id
  name            = "app-health-probe"
  protocol        = "Http"
  port            = var.app_health_probe_port
  request_path    = "/health"
  interval_in_seconds = 15
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "app_lb_rule" {
  loadbalancer_id                = azurerm_lb.app_lb.id
  name                           = "app-lb-rule"
  protocol                       = "Tcp"
  frontend_port                  = 8080
  backend_port                   = 8080
  frontend_ip_configuration_name = "app-lb-frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.app_backend_pool.id]
  probe_id                       = azurerm_lb_probe.app_health_probe.id
  disable_outbound_snat          = false
  enable_floating_ip             = false
  idle_timeout_in_minutes        = 4
}

resource "azurerm_network_interface_backend_address_pool_association" "app_nic_lb_association" {
  network_interface_id    = azurerm_network_interface.app_nic.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.app_backend_pool.id
}
