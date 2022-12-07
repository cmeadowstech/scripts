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

terraform {
  backend "azurerm" {
    resource_group_name  = "tf-rg"
    storage_account_name = "tfstorage665189"
    container_name       = "tf-state"
    key                  = "global-workspace/terraform.tfstate"
  }
}

variable "prefix" {
    default = "tf"  
}

resource "azurerm_resource_group" "rg" {
  name = "${var.prefix}-rg"
  location = "East US"
}

resource "azurerm_storage_account" "storage" {
  name = "${var.prefix}storage665189"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  account_kind = "StorageV2"
  account_tier = "Standard"
  account_replication_type = "LRS"
  infrastructure_encryption_enabled = true

  blob_properties {
    versioning_enabled = true
  }
}

resource "azurerm_storage_container" "container" {
  name = "${var.prefix}-state"
  storage_account_name = azurerm_storage_account.storage.name
}

resource "azurerm_virtual_network" "vnet" {
    name = "${var.prefix}-vnet"
    address_space = [ "10.0.0.0/16"]
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}

output "location" {
  value = azurerm_resource_group.rg.location
}
output "rgName" {
  value = azurerm_resource_group.rg.name
}
output "vnet" {
  value = azurerm_virtual_network.vnet
}