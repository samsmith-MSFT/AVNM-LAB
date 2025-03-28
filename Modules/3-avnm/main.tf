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
  name                      = "members"
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

resource "azurerm_network_manager_security_admin_configuration" "security-config" {
  name                                          = "security-conf"
  network_manager_id                            = azurerm_network_manager.avnm.id
  description                                   = "example security conf"
  apply_on_network_intent_policy_based_services = ["None"]
}

resource "azurerm_network_manager_admin_rule_collection" "security-rule-collection" {
  name                            = "security-rule-collection"
  security_admin_configuration_id = azurerm_network_manager_security_admin_configuration.security-config.id
  network_group_ids               = [azurerm_network_manager_network_group.ng.id]
}

resource "azurerm_network_manager_admin_rule" "admin-rule-1" {
  name                     = "admin-rule-1"
  admin_rule_collection_id = azurerm_network_manager_admin_rule_collection.security-rule-collection.id
  action                   = "Deny"
  direction                = "Outbound"
  priority                 = 1
  protocol                 = "Tcp"
  source_port_ranges       = ["0-65535"]
  destination_port_ranges  = ["80", "443"]
  source {
    address_prefix_type = "ServiceTag"
    address_prefix      = "VirtualNetwork"
  }
  destination {
    address_prefix_type = "ServiceTag"
    address_prefix      = "Internet"
  }
  description = "Blocks all HTTP traffic to Internet"
}

resource "azurerm_network_manager_admin_rule" "admin-rule-2" {
  name                     = "admin-rule-2"
  admin_rule_collection_id = azurerm_network_manager_admin_rule_collection.security-rule-collection.id
  action                   = "Deny"
  direction                = "Inbound"
  priority                 = 1
  protocol                 = "Tcp"
  source_port_ranges       = ["0-65535"]
  destination_port_ranges  = ["22"]
  source {
    address_prefix_type = "ServiceTag"
    address_prefix      = "VirtualNetwork"
  }
  destination {
    address_prefix_type = "IPPrefix"
    address_prefix      = "10.3.0.4"
  }
  description = "Blocks SSH to 10.3.0.4"
}

resource "azurerm_network_manager_deployment" "connectivity-deployment" {
  network_manager_id = azurerm_network_manager.avnm.id
  location           = "eastus2"
  scope_access       = "Connectivity"
  configuration_ids  = [azurerm_network_manager_connectivity_configuration.connectivity-config.id]
}

resource "azurerm_network_manager_deployment" "Security-deployment" {
  network_manager_id = azurerm_network_manager.avnm.id
  location           = "eastus2"
  scope_access       = "SecurityAdmin"
  configuration_ids  = [azurerm_network_manager_security_admin_configuration.security-config.id]
}

resource "azurerm_network_manager_verifier_workspace" "verifier-workspace" {
  name               = "verifier-workspace-example"
  network_manager_id = azurerm_network_manager.avnm.id
  location           = data.azurerm_resource_group.rg.location
  description        = "This is an example verifier workspace"
}
