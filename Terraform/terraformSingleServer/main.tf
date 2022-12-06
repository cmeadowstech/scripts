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
  default = 8080
}

resource "azurerm_resource_group" "rg" {
    name = "${var.prefix}Test"
    location = "East US"
}

resource "azurerm_virtual_network" "vnet" {
    name = "${var.prefix}Vnet"
    address_space = [ "10.0.0.0/16"]
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
    name = "Internal"
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes = [ "10.0.2.0/24" ]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "terraformVnet-Internal-nsg-eastus"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

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

resource "azurerm_public_ip" "publicIp" {
  name                = "${var.prefix}PublicIP34566"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "interface" {
    name = "${var.prefix}-nix"  
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    ip_configuration {
      name = "testconfiguration1"
      subnet_id = azurerm_subnet.subnet.id
      private_ip_address_allocation = "Dynamic"
      public_ip_address_id = azurerm_public_ip.publicIp.id
    }
}

resource "azurerm_virtual_machine" "vm" {
    name = "${var.prefix}-vm"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    network_interface_ids = [azurerm_network_interface.interface.id]
    vm_size = "Standard_DS1_v2"

    delete_data_disks_on_termination = true
    delete_os_disk_on_termination = true
    
    storage_image_reference {
      publisher = "Canonical"
      offer = "UbuntuServer"
      sku = "16.04-LTS"
      version = "latest"
    }
    storage_os_disk {
      name = "myosdisk1"
      caching = "ReadWrite"
      create_option = "FromImage"
      managed_disk_type = "Standard_LRS"
    }
    os_profile {
      computer_name = "hostname"
      admin_username = "cmeadows"
      admin_password = "#1W7!Bm1GeXg"
      custom_data = <<-EOF
        #!/bin/bash
        echo "Hello, World" > index.html
        nohup busybox httpd -f -p ${var.port} &
      EOF
      
    }
    os_profile_linux_config {
      disable_password_authentication = false
    }
    tags = {
      "environment" = "staging"
    }
}

output "publicIp" {
  value = azurerm_public_ip.publicIp.ip_address
  description = "The public IP address of the web server"
}