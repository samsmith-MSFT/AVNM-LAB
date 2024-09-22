variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Location of Azure resource"
  default     = "northcentralus"
  type        = string
}

variable "subnet_space_spokes" {
  description = "Subnet space of the virtual network"
  type        = map(list(string))
}

variable "vnet_name_spokes" {
  description = "Name of the virtual network"
  type        = list(string)
}

variable "subscription_id" {
  description = "Subscription ID"
  type        = string
}