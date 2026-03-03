variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group containing the AVNM resources"
}

variable "location" {
  type        = string
  description = "The Azure region for AVNM deployments"
  default     = "eastus2"
}

variable "avnm_name" {
  type        = string
  description = "The name of the existing Azure Virtual Network Manager"
  default     = "avnm-hub-spoke"
}
