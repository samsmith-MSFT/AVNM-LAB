###############################################################################
# Module 3: AVNM Security Admin Rules & UDR (Routing) Management
# This module adds Security Admin Rules and Routing Configuration to the
# existing AVNM instance created in Module 1.
###############################################################################

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

###############################################################################
# Data Sources - Reference resources from Module 1
###############################################################################

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_network_manager" "avnm" {
  name                = var.avnm_name
  resource_group_name = var.resource_group_name
}

data "azurerm_network_manager_network_group" "spoke_group" {
  name               = "hub-spoke-group"
  network_manager_id = data.azurerm_network_manager.avnm.id
}

data "azurerm_firewall" "firewall" {
  name                = "azfw-hub"
  resource_group_name = var.resource_group_name
}

###############################################################################
# PART 1: Security Admin Rules
# Centrally enforced network security rules that override NSG rules.
# These demonstrate how AVNM can enforce organizational security policies
# that local VNet owners cannot bypass.
###############################################################################

# Security Admin Configuration
resource "azurerm_network_manager_security_admin_configuration" "security_config" {
  name                                          = "avnm-security-admin-config"
  network_manager_id                            = data.azurerm_network_manager.avnm.id
  description                                   = "Security admin rules enforced across all spoke VNets"
  apply_on_network_intent_policy_based_services = ["None"]
}

# Rule Collection - groups rules together and targets them at the spoke network group
resource "azurerm_network_manager_admin_rule_collection" "spoke_rules" {
  name                            = "spoke-security-rules"
  security_admin_configuration_id = azurerm_network_manager_security_admin_configuration.security_config.id
  network_group_ids               = [data.azurerm_network_manager_network_group.spoke_group.id]
  description                     = "Security admin rules applied to all spoke VNets"
}

# Rule 1: Always allow ICMP for diagnostics (AlwaysAllow overrides any Deny)
resource "azurerm_network_manager_admin_rule" "allow_icmp" {
  name                     = "AlwaysAllow-ICMP"
  admin_rule_collection_id = azurerm_network_manager_admin_rule_collection.spoke_rules.id
  action                   = "AlwaysAllow"
  direction                = "Inbound"
  priority                 = 1
  protocol                 = "Icmp"
  description              = "Always allow ICMP for network diagnostics - cannot be overridden by NSGs"
}

# Rule 2: Deny inbound SSH from the internet (enforced - local NSGs cannot override)
resource "azurerm_network_manager_admin_rule" "deny_ssh_internet" {
  name                     = "Deny-SSH-From-Internet"
  admin_rule_collection_id = azurerm_network_manager_admin_rule_collection.spoke_rules.id
  action                   = "Deny"
  direction                = "Inbound"
  priority                 = 10
  protocol                 = "Tcp"
  destination_port_ranges  = ["22"]
  source {
    address_prefix_type = "ServiceTag"
    address_prefix      = "Internet"
  }
  description = "Deny SSH from the internet - enforced across all spokes"
}

# Rule 3: Deny inbound RDP from the internet
resource "azurerm_network_manager_admin_rule" "deny_rdp_internet" {
  name                     = "Deny-RDP-From-Internet"
  admin_rule_collection_id = azurerm_network_manager_admin_rule_collection.spoke_rules.id
  action                   = "Deny"
  direction                = "Inbound"
  priority                 = 20
  protocol                 = "Tcp"
  destination_port_ranges  = ["3389"]
  source {
    address_prefix_type = "ServiceTag"
    address_prefix      = "Internet"
  }
  description = "Deny RDP from the internet - enforced across all spokes"
}

# Rule 4: Deny high-risk outbound ports (Telnet, FTP data/control)
resource "azurerm_network_manager_admin_rule" "deny_high_risk_outbound" {
  name                     = "Deny-HighRisk-Outbound"
  admin_rule_collection_id = azurerm_network_manager_admin_rule_collection.spoke_rules.id
  action                   = "Deny"
  direction                = "Outbound"
  priority                 = 100
  protocol                 = "Tcp"
  destination_port_ranges  = ["23", "20", "21"]
  destination {
    address_prefix_type = "ServiceTag"
    address_prefix      = "Internet"
  }
  description = "Deny high-risk outbound protocols (Telnet, FTP) to the internet"
}

# Rule 5: Allow inbound traffic from within the 10.0.0.0/8 range (internal communication)
resource "azurerm_network_manager_admin_rule" "allow_internal" {
  name                     = "Allow-Internal-Traffic"
  admin_rule_collection_id = azurerm_network_manager_admin_rule_collection.spoke_rules.id
  action                   = "Allow"
  direction                = "Inbound"
  priority                 = 200
  protocol                 = "Any"
  source {
    address_prefix_type = "IPPrefix"
    address_prefix      = "10.0.0.0/8"
  }
  description = "Allow inbound traffic from internal RFC1918 ranges"
}

# Deploy Security Admin Configuration
resource "azurerm_network_manager_deployment" "security_deployment" {
  network_manager_id = data.azurerm_network_manager.avnm.id
  location           = var.location
  scope_access       = "SecurityAdmin"
  configuration_ids  = [azurerm_network_manager_security_admin_configuration.security_config.id]
  triggers = {
    security_config_id = azurerm_network_manager_security_admin_configuration.security_config.id
    rules_hash = sha256(join(",", [
      azurerm_network_manager_admin_rule.allow_icmp.id,
      azurerm_network_manager_admin_rule.deny_ssh_internet.id,
      azurerm_network_manager_admin_rule.deny_rdp_internet.id,
      azurerm_network_manager_admin_rule.deny_high_risk_outbound.id,
      azurerm_network_manager_admin_rule.allow_internal.id,
    ]))
  }
}

###############################################################################
# PART 2: UDR Management (Routing Configuration)
# Centrally managed route tables pushed to spoke VNets via AVNM.
# Demonstrates how AVNM can manage routing at scale, forcing traffic
# through the Azure Firewall without manually managing UDRs per subnet.
###############################################################################

# Routing Configuration
resource "azurerm_network_manager_routing_configuration" "routing_config" {
  name               = "avnm-routing-config"
  network_manager_id = data.azurerm_network_manager.avnm.id
  description        = "AVNM-managed routing configuration for spoke VNets - routes traffic through Azure Firewall"
}

# Routing Rule Collection - targets spoke network group
resource "azurerm_network_manager_routing_rule_collection" "spoke_routing" {
  name                     = "spoke-routing-rules"
  routing_configuration_id = azurerm_network_manager_routing_configuration.routing_config.id
  network_group_ids        = [data.azurerm_network_manager_network_group.spoke_group.id]
  description              = "Routing rules applied to all spoke VNets - forces traffic through firewall"
}

# Routing Rule 1: Route internet-bound traffic through Azure Firewall
resource "azurerm_network_manager_routing_rule" "internet_to_firewall" {
  name               = "Internet-Via-Firewall"
  rule_collection_id = azurerm_network_manager_routing_rule_collection.spoke_routing.id
  description        = "Route all internet-bound traffic through Azure Firewall"

  destination {
    type    = "AddressPrefix"
    address = "0.0.0.0/0"
  }

  next_hop {
    type    = "VirtualAppliance"
    address = data.azurerm_firewall.firewall.ip_configuration[0].private_ip_address
  }
}

# Routing Rule 2: Route spoke-to-spoke traffic through Azure Firewall (10.0.0.0/8)
resource "azurerm_network_manager_routing_rule" "private_via_firewall" {
  name               = "Private-RFC1918-Via-Firewall"
  rule_collection_id = azurerm_network_manager_routing_rule_collection.spoke_routing.id
  description        = "Route private network traffic through Azure Firewall for inspection"

  destination {
    type    = "AddressPrefix"
    address = "10.0.0.0/8"
  }

  next_hop {
    type    = "VirtualAppliance"
    address = data.azurerm_firewall.firewall.ip_configuration[0].private_ip_address
  }
}

# Deploy Routing Configuration
resource "azurerm_network_manager_deployment" "routing_deployment" {
  network_manager_id = data.azurerm_network_manager.avnm.id
  location           = var.location
  scope_access       = "Routing"
  configuration_ids  = [azurerm_network_manager_routing_configuration.routing_config.id]
  triggers = {
    routing_config_id = azurerm_network_manager_routing_configuration.routing_config.id
    rules_hash = sha256(join(",", [
      azurerm_network_manager_routing_rule.internet_to_firewall.id,
      azurerm_network_manager_routing_rule.private_via_firewall.id,
    ]))
  }
}
