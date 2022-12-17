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
    key                  = "stage-workspace/terraform.tfstate"
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

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"
  ssPassword = var.db_password
  ssUsername = var.db_username
  prefix = "tf"
  db_remote_state_storage_name = data.terraform_remote_state.global.outputs.storageName
  db_remote_state_container = data.terraform_remote_state.global.outputs.containerName
  db_remote_state_key = "db-workspace/terraform.tfstate"
  resource_group_name = data.terraform_remote_state.global.outputs.rgName
  location = data.terraform_remote_state.global.outputs.location
  vnetName = data.terraform_remote_state.global.outputs.vnet.name
  skuName = "Standard_B1ls"
  min_count = 2
  max_count = 4
}

variable "db_username" {
  type = string
  sensitive = true
}

variable "db_password" {
  type = string
  sensitive = true
}

output "publicIp" {
  value = module.webserver_cluster.publicIp
  description = "The public IP address of the web server"
}