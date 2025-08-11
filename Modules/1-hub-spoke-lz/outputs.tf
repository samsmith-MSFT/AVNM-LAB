output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.rg.name
}

output "hub_vnet_id" {
  description = "ID of the hub virtual network"
  value       = azurerm_virtual_network.hub_vnet.id
}

output "spoke_vnet_ids" {
  description = "IDs of the spoke virtual networks"
  value       = { for k, v in azurerm_virtual_network.spoke_vnets : k => v.id }
}

output "network_manager_id" {
  description = "ID of the Azure Virtual Network Manager"
  value       = azurerm_network_manager.avnm.id
}

output "ipam_pool_id" {
  description = "ID of the IPAM pool"
  value       = azurerm_network_manager_ipam_pool.main_pool.id
}

output "spoke_subnet_ids" {
  description = "IDs of the spoke subnets"
  value       = { for k, v in azurerm_subnet.spoke_subnets : k => v.id }
}

output "spoke_subnet_allocated_prefixes" {
  description = "Allocated IP address prefixes for spoke subnets"
  value       = { for k, v in azurerm_subnet.spoke_subnets : k => v.ip_address_pool[0].allocated_ip_address_prefixes }
}

# AVNM Configuration Outputs
output "network_group_id" {
  description = "ID of the network group containing spoke VNets"
  value       = azurerm_network_manager_network_group.spoke_group.id
}

output "connectivity_configuration_id" {
  description = "ID of the hub-spoke connectivity configuration"
  value       = azurerm_network_manager_connectivity_configuration.hub_spoke_config.id
}

output "deployment_id" {
  description = "ID of the connectivity deployment"
  value       = azurerm_network_manager_deployment.connectivity_deployment.id
}

output "verifier_workspace_id" {
  description = "ID of the verifier workspace"
  value       = azurerm_network_manager_verifier_workspace.verifier_workspace.id
}