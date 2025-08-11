terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Azure Virtual Network Manager for IP Address Management
resource "azurerm_network_manager" "avnm" {
  name                = var.avnm_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  scope {
    subscription_ids = ["/subscriptions/${var.subscription_id}"]
  }
  scope_accesses = ["Connectivity", "SecurityAdmin"]
  description    = "Network manager for hub-spoke topology with IPAM"
}

# IPAM Pool for subnet address allocation
resource "azurerm_network_manager_ipam_pool" "main_pool" {
  name               = "main-ipam-pool"
  location           = var.location
  network_manager_id = azurerm_network_manager.avnm.id
  display_name       = "Main IP Address Pool"
  address_prefixes   = [var.ipam_pool_address_prefix]
  description        = "Main IP address pool for spoke subnet allocation"
}

# Network Group for organizing spoke VNets
resource "azurerm_network_manager_network_group" "spoke_group" {
  network_manager_id = azurerm_network_manager.avnm.id
  name               = "hub-spoke-group"
  description        = "Network group containing all spoke virtual networks"
}

# Add spoke VNets to the network group
resource "azurerm_network_manager_static_member" "spoke_members" {
  for_each                  = toset(var.vnet_name_spokes)
  name                      = "${each.key}-member"
  network_group_id          = azurerm_network_manager_network_group.spoke_group.id
  target_virtual_network_id = azurerm_virtual_network.spoke_vnets[each.key].id
}

# Connectivity configuration for hub-spoke topology
resource "azurerm_network_manager_connectivity_configuration" "hub_spoke_config" {
  name                  = "hub-spoke-connectivity"
  network_manager_id    = azurerm_network_manager.avnm.id
  connectivity_topology = "HubAndSpoke"
  description           = "Hub and spoke connectivity configuration"
  
  applies_to_group {
    group_connectivity = "None"
    network_group_id   = azurerm_network_manager_network_group.spoke_group.id
  }

  hub {
    resource_id   = azurerm_virtual_network.hub_vnet.id
    resource_type = "Microsoft.Network/virtualNetworks"
  }
}

# Deploy the connectivity configuration
resource "azurerm_network_manager_deployment" "connectivity_deployment" {
  network_manager_id = azurerm_network_manager.avnm.id
  location           = var.location
  scope_access       = "Connectivity"
  configuration_ids  = [azurerm_network_manager_connectivity_configuration.hub_spoke_config.id]
  triggers = {
    connectivity_config_id = azurerm_network_manager_connectivity_configuration.hub_spoke_config.id
  }
}

# Optional: Verifier workspace for network verification
resource "azurerm_network_manager_verifier_workspace" "verifier_workspace" {
  name               = "hub-spoke-verifier"
  network_manager_id = azurerm_network_manager.avnm.id
  location           = var.location
  description        = "Verifier workspace for hub-spoke network topology"
}

resource "azurerm_virtual_network" "hub_vnet" {
  name                = var.vnet_name_hub
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.address_space_hub
  tags = {
    environment = "hub"
  }
}

resource "azurerm_virtual_network" "spoke_vnets" {
  for_each             = toset(var.vnet_name_spokes)
  name                 = each.value
  location             = var.location
  resource_group_name  = azurerm_resource_group.rg.name
  address_space        = var.address_space_spokes[each.key]
  tags = {
    environment = "spoke"
  }
}

resource "azurerm_subnet" "spoke_subnets" {
  for_each             = toset(var.vnet_name_spokes)
  name                 = "${each.key}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke_vnets[each.key].name
  
  # Use IP address pool allocation instead of static prefixes
  ip_address_pool {
    id                      = azurerm_network_manager_ipam_pool.main_pool.id
    number_of_ip_addresses  = var.subnet_ip_count
  }
  
  depends_on = [azurerm_virtual_network.spoke_vnets, azurerm_network_manager_ipam_pool.main_pool]
}

resource "azurerm_network_security_group" "spoke_nsgs" {
  for_each             = toset(var.vnet_name_spokes)
  name                 = "${each.key}-nsg"
  location             = var.location
  resource_group_name  = azurerm_resource_group.rg.name
  tags = {
    environment = "spoke"
  }
}

resource "azurerm_subnet_network_security_group_association" "spoke_nsg_association" {
  for_each             = toset(var.vnet_name_spokes)
  subnet_id            = azurerm_subnet.spoke_subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.spoke_nsgs[each.key].id
}

resource "azurerm_subnet" "hub_fw_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = var.subnet_space_fw
  depends_on           = [azurerm_virtual_network.hub_vnet]
}

resource "azurerm_firewall_policy" "firewall_policy" {
  name                = "azfw-hub-policy"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
}

resource "azurerm_firewall_policy_rule_collection_group" "rcg" {
  name               = "demo-fwpolicy-rcg"
  firewall_policy_id = azurerm_firewall_policy.firewall_policy.id
  priority           = 500
  network_rule_collection {
    name     = "network_rule_collection1"
    priority = 400
    action   = "Allow"
    rule {
      name                  = "network_rule_collection1_rule1"
      protocols             = ["TCP", "UDP", "ICMP"]
      source_addresses      = ["10.0.0.0/8"]
      destination_addresses = ["10.0.0.0/8"]
      destination_ports     = ["*"]
    }
    rule {
      name                  = "network_rule_collection1_rule2"
      protocols             = ["TCP", "UDP", "ICMP"]
      source_addresses      = ["10.0.0.0/8"]
      destination_addresses = ["0.0.0.0/0"]
      destination_ports     = ["*"]
    }
  }
}

resource "azurerm_firewall" "firewall" {
  name                = "azfw-hub"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  firewall_policy_id  = azurerm_firewall_policy.firewall_policy.id
  ip_configuration {
    name                          = "FirewallIpConfig"
    subnet_id                     = azurerm_subnet.hub_fw_subnet.id
    public_ip_address_id          = azurerm_public_ip.firewall.id
  }
}

resource "azurerm_public_ip" "firewall" {
  name                = "firewall-ip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_route_table" "rt" {
  name                = "avnm-route-table"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  bgp_route_propagation_enabled = false
  route {
    name           = "default-route"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "rt_association" {
  for_each             = toset(var.vnet_name_spokes)
  subnet_id            = azurerm_subnet.spoke_subnets[each.key].id
  route_table_id       = azurerm_route_table.rt.id
  depends_on           = [azurerm_route_table.rt]
}
