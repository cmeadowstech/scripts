data "terraform_remote_state" "db" {
  backend = "azurerm" 
  config = {
    resource_group_name  = var.resource_group_name
    storage_account_name = var.db_remote_state_storage_name
    container_name       = var.db_remote_state_container
    key                  = var.db_remote_state_key
  }
}

locals {
  frontend_port = 80
  backend_port = 8090
}

resource "azurerm_subnet" "subnet" {
    name = "${var.prefix}-subnet"
    resource_group_name = var.resource_group_name
    virtual_network_name = var.vnetName
    address_prefixes = [ "10.0.2.0/24" ]
}

resource "azurerm_public_ip" "publicIp" {
  name                = "${var.prefix}-publicIP"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku = "Standard"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = local.backend_port
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_lb" "loadbalancer" {
  name = "${var.prefix}-lb"
  location = var.location
  resource_group_name = var.resource_group_name
  sku = "Standard"

  frontend_ip_configuration {
    name = "${var.prefix}-public-ip"
    public_ip_address_id = azurerm_public_ip.publicIp.id
  }
}

resource "azurerm_lb_backend_address_pool" "bepool" {
  loadbalancer_id = azurerm_lb.loadbalancer.id
  name = "${var.prefix}-bepool"
}

resource "azurerm_lb_nat_pool" "lbnatpool" {
  name = "SSH"
  resource_group_name = var.resource_group_name
  loadbalancer_id = azurerm_lb.loadbalancer.id
  protocol = "Tcp"
  frontend_port_start = 50000
  frontend_port_end = 50119
  backend_port = 22
  frontend_ip_configuration_name = azurerm_lb.loadbalancer.frontend_ip_configuration[0].name
}

resource "azurerm_lb_probe" "lbprobe" {
  loadbalancer_id = azurerm_lb.loadbalancer.id
  name = "http-probe"
  protocol = "Tcp"
  port = local.backend_port
}

resource "azurerm_lb_rule" "lbHttpRule" {
  name = "lbHttpRule"
  loadbalancer_id = azurerm_lb.loadbalancer.id
  protocol = "Tcp"
  frontend_port = local.frontend_port
  backend_port = local.backend_port
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.bepool.id]
  probe_id = azurerm_lb_probe.lbprobe.id
  frontend_ip_configuration_name = azurerm_lb.loadbalancer.frontend_ip_configuration[0].name
}

resource "azurerm_virtual_machine_scale_set" "scaleSet" {
  name = "${var.prefix}-scaleset"
  location = var.location
  resource_group_name = var.resource_group_name

  depends_on = [
    azurerm_lb_rule.lbHttpRule
  ]

  upgrade_policy_mode = "Automatic"

  sku {
    name = var.skuName
    tier = "Standard"
    capacity = var.min_count
  }
  
  health_probe_id = azurerm_lb_probe.lbprobe.id

  storage_profile_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "16.04-LTS"
    version = "latest"
  }

  storage_profile_os_disk {
    name = ""
    caching = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name_prefix = "${var.prefix}-ss-instance"
    admin_username = var.ssUsername
    admin_password = var.ssPassword
    custom_data = templatefile ("${path.module}/user-data.sh", {
      server_address = data.terraform_remote_state.db.outputs.sqlAddess
      server_port = local.backend_port
      }
    )
  }
      
  network_profile {
    name = "${var.prefix}-network-profile"
    primary = true
    network_security_group_id = azurerm_network_security_group.nsg.id

    ip_configuration {
      name = "TestIPConfiguration"
      primary = true
      subnet_id = azurerm_subnet.subnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bepool.id]
      load_balancer_inbound_nat_rules_ids = [azurerm_lb_nat_pool.lbnatpool.id]
    }
  }
  tags = {
    "environment" = "staging"
  }
}

resource "azurerm_monitor_autoscale_setting" "autoscale" {
name                = "myAutoscaleSetting"
resource_group_name = var.resource_group_name
location            = var.location
target_resource_id  = azurerm_virtual_machine_scale_set.scaleSet.id

profile {
  name = "Weekends"

  capacity {
    default = var.min_count
    minimum = var.min_count
    maximum = var.max_count
  }

  rule {
    metric_trigger {
      metric_name        = "Percentage CPU"
      metric_resource_id = azurerm_virtual_machine_scale_set.scaleSet.id
      time_grain         = "PT1M"
      statistic          = "Average"
      time_window        = "PT5M"
      time_aggregation   = "Average"
      operator           = "GreaterThan"
      threshold          = 90
    }

    scale_action {
      direction = "Increase"
      type      = "ChangeCount"
      value     = "2"
      cooldown  = "PT1M"
    }
  }

  rule {
    metric_trigger {
      metric_name        = "Percentage CPU"
      metric_resource_id = azurerm_virtual_machine_scale_set.scaleSet.id
      time_grain         = "PT1M"
      statistic          = "Average"
      time_window        = "PT5M"
      time_aggregation   = "Average"
      operator           = "LessThan"
      threshold          = 10
    }

    scale_action {
      direction = "Decrease"
      type      = "ChangeCount"
      value     = "2"
      cooldown  = "PT1M"
    }
  }

  recurrence {
    timezone = "Pacific Standard Time"
    days     = ["Saturday", "Sunday"]
    hours    = [12]
    minutes  = [0]
  }
}
}

output "publicIp" {
  value = azurerm_public_ip.publicIp.ip_address
  description = "The public IP address of the web server"
}