terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

data "azurerm_virtual_network" "hub-vnet" {
  name                = var.vnet_name_hub
  resource_group_name = var.resource_group_name
}

data "azurerm_virtual_network" "spoke_vnets" {
  for_each = toset(var.vnet_name_spokes)
  name                = each.value
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
}

resource "azurerm_network_manager" "avnm" {
  name                = var.avnm_name
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  scope {
    subscription_ids = ["/subscriptions/${var.subscription_id}"]
  }
  scope_accesses = ["Connectivity", "SecurityAdmin"]
  description    = "example network manager"
}

resource "azurerm_network_manager_network_group" "ng" {
  network_manager_id   = azurerm_network_manager.avnm.id
  name                 = "hub-spoke"
}

resource "azurerm_network_manager_static_member" "members" {
  for_each = toset(var.vnet_name_spokes)
  name                      = "${each.key}"
  network_group_id          = azurerm_network_manager_network_group.ng.id
  target_virtual_network_id = data.azurerm_virtual_network.spoke_vnets[each.key].id
}

resource "azurerm_network_manager_connectivity_configuration" "connectivity-config" {
  name                  = "connectivity-conf"
  network_manager_id    = azurerm_network_manager.avnm.id
  connectivity_topology = "HubAndSpoke"
  applies_to_group {
    group_connectivity = "None"
    network_group_id   = azurerm_network_manager_network_group.ng.id
  }

  hub {
    resource_id   = data.azurerm_virtual_network.hub-vnet.id
    resource_type = "Microsoft.Network/virtualNetworks"
  }
}

resource "azurerm_network_manager_deployment" "connectivity-deployment" {
  network_manager_id = azurerm_network_manager.avnm.id
  location           = "eastus2"
  scope_access       = "Connectivity"
  configuration_ids  = [azurerm_network_manager_connectivity_configuration.connectivity-config.id]
}

resource "azurerm_network_manager_verifier_workspace" "verifier-workspace" {
  name               = "verifier-workspace-example"
  network_manager_id = azurerm_network_manager.avnm.id
  location           = data.azurerm_resource_group.rg.location
  description        = "This is an example verifier workspace"
}
