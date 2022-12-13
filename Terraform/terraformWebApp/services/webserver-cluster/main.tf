terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.33.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "prefix" {
    default = "terraform"  
}

variable "port" {
  description = "The port the server will use for HTTP requests"
  type = number
  default = 8090
}

variable "db_username" {
  type = string
  sensitive = true
}

variable "db_password" {
  type = string
  sensitive = true
}

terraform {
  backend "azurerm" {
    resource_group_name  = "tf-rg"
    storage_account_name = "tfstorage665189"
    container_name       = "tf-state"
    key                  = "web-cluster-workspace/terraform.tfstate"
  }
}

data "terraform_remote_state" "global" {
  backend = "azurerm" 
  config = {
    resource_group_name  = "tf-rg"
    storage_account_name = "tfstorage665189"
    container_name       = "tf-state"
    key                  = "global-workspace/terraform.tfstate"
  }
}

data "terraform_remote_state" "db" {
  backend = "azurerm" 
  config = {
    resource_group_name  = "tf-rg"
    storage_account_name = "tfstorage665189"
    container_name       = "tf-state"
    key                  = "db-workspace/terraform.tfstate"
  }
}

resource "azurerm_subnet" "subnet" {
    name = "${var.prefix}-subnet"
    resource_group_name = data.terraform_remote_state.global.outputs.rgName
    virtual_network_name = data.terraform_remote_state.global.outputs.vnet.name
    address_prefixes = [ "10.0.2.0/24" ]
}

resource "azurerm_public_ip" "publicIp" {
  name                = "${var.prefix}-publicIP"
  resource_group_name = data.terraform_remote_state.global.outputs.rgName
  location            = data.terraform_remote_state.global.outputs.location
  allocation_method   = "Static"
  sku = "Standard"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = data.terraform_remote_state.global.outputs.location
  resource_group_name = data.terraform_remote_state.global.outputs.rgName

  security_rule {
    name                       = "http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = var.port
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
  location = data.terraform_remote_state.global.outputs.location
  resource_group_name = data.terraform_remote_state.global.outputs.rgName
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
  resource_group_name = data.terraform_remote_state.global.outputs.rgName
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
  port = var.port
}

resource "azurerm_lb_rule" "lbHttpRule" {
  name = "lbHttpRule"
  loadbalancer_id = azurerm_lb.loadbalancer.id
  protocol = "Tcp"
  frontend_port = 80
  backend_port = var.port
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.bepool.id]
  probe_id = azurerm_lb_probe.lbprobe.id
  frontend_ip_configuration_name = azurerm_lb.loadbalancer.frontend_ip_configuration[0].name
}

resource "azurerm_virtual_machine_scale_set" "scaleSet" {
    name = "${var.prefix}-scaleset"
    location = data.terraform_remote_state.global.outputs.location
    resource_group_name = data.terraform_remote_state.global.outputs.rgName

    depends_on = [
      azurerm_lb_rule.lbHttpRule
    ]

    upgrade_policy_mode = "Automatic"

    sku {
      name = "Standard_B1ls"
      tier = "Standard"
      capacity = 2
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
      admin_username = var.db_username
      admin_password = var.db_password
      custom_data = templatefile ("user-data.sh", {
        server_address = data.terraform_remote_state.db.outputs.sqlAddess
        server_port = var.port
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

output "publicIp" {
  value = azurerm_public_ip.publicIp.ip_address
  description = "The public IP address of the web server"
}