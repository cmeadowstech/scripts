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
    key                  = "db-workspace/terraform.tfstate"
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

variable "prefix" {
    default = "tf"  
}

resource "azurerm_mssql_server" "sqlserver" {
  name = "${var.prefix}-sql-server-4308"
  location = data.terraform_remote_state.global.outputs.location
  resource_group_name = data.terraform_remote_state.global.outputs.rgName
  version = "12.0"
  administrator_login = "4dm1n157r470r"
  administrator_login_password = "#1W7!Bm1GeXg"
}

resource "azurerm_mssql_database" "sqldb" {
  name = "${var.prefix}-sql-db"
  server_id = azurerm_mssql_server.sqlserver.id
  sku_name = "Basic"
  license_type = "LicenseIncluded"
  zone_redundant = false
}