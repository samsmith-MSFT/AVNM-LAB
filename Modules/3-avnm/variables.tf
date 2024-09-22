variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Location of Azure resource"
  default     = "eastus2"
  type        = string
}

variable "avnm_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "subscription_id" {
  description = "Subscription ID"
  type        = string
}

variable "vnet_name_hub" {
  description = "Name of the virtual network"
  type        = string
}