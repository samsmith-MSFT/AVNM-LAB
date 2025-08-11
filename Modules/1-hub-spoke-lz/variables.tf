variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Location of Azure resource"
  default     = "eastus2"
  type        = string
}

variable "vnet_name_hub" {
  description = "Name of the virtual network"
  type        = string
}

variable "firewall_subnet_ip_count" {
  description = "Number of IP addresses to allocate for firewall subnet"
  type        = string
  default     = "256"
}

variable "vnet_name_spokes" {
  description = "Name of the virtual network"
  type        = list(string)
}

variable "subscription_id" {
  description = "Subscription ID"
  type        = string
}

variable "avnm_name" {
  description = "Name of the Azure Virtual Network Manager"
  type        = string
  default     = "avnm-hub-spoke"
}

variable "ipam_pool_address_prefix" {
  description = "Address prefix for the IPAM pool"
  type        = string
  default     = "10.0.0.0/14"
}

variable "subnet_ip_count" {
  description = "Number of IP addresses to allocate per spoke subnet"
  type        = string
  default     = "32"
}

variable "vnet_ip_count" {
  description = "Number of IP addresses to allocate per spoke VNet"
  type        = string
  default     = "256"
}

variable "hub_vnet_ip_count" {
  description = "Number of IP addresses to allocate for hub VNet"
  type        = string
  default     = "65536"
}
