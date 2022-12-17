variable "prefix" {
  description = "The name to use for all the cluster resources"
  type = string
}

variable "db_remote_state_storage_name" {
  description = "Name of the storage account"
  type = string
}

variable "db_remote_state_container" {
  description = "The name of the container for the database's remote state"
  type = string
}

variable "db_remote_state_key" {
  description = "The path for the database's remote state in the container"
  type = string
}

variable "resource_group_name" {
  description = "Name of the resource group you are deploying this too"
  type = string
}

variable "location" {
  description = "Location of resources"
  type = string
}

variable "vnetName" {
  description = "VNet object from remote state"
  type = string
}

variable "ssUsername" {
  type = string
  sensitive = true
}

variable "ssPassword" {
  type = string
  sensitive = true
}

variable "port" {
  description = "The port the server will use for HTTP requests"
  type = number
  default = 8090
}

variable "skuName" {
  description = "SKU of Scale Set"
  type = string
}

variable "min_count" {
  description = "Minumum number of instances in scale set"
  type = number
}

variable "max_count" {
  description = "Maximum number of instances in scale set"
  type = number
}