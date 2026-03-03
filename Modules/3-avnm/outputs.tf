output "security_admin_configuration_id" {
  value       = azurerm_network_manager_security_admin_configuration.security_config.id
  description = "The ID of the Security Admin Configuration"
}

output "security_admin_deployment_id" {
  value       = azurerm_network_manager_deployment.security_deployment.id
  description = "The ID of the Security Admin deployment"
}

output "routing_configuration_id" {
  value       = azurerm_network_manager_routing_configuration.routing_config.id
  description = "The ID of the Routing Configuration"
}

output "routing_deployment_id" {
  value       = azurerm_network_manager_deployment.routing_deployment.id
  description = "The ID of the Routing deployment"
}

output "security_rules" {
  value = {
    allow_icmp            = azurerm_network_manager_admin_rule.allow_icmp.id
    deny_ssh_internet     = azurerm_network_manager_admin_rule.deny_ssh_internet.id
    deny_rdp_internet     = azurerm_network_manager_admin_rule.deny_rdp_internet.id
    deny_high_risk_outbound = azurerm_network_manager_admin_rule.deny_high_risk_outbound.id
    allow_internal        = azurerm_network_manager_admin_rule.allow_internal.id
  }
  description = "Map of Security Admin Rule IDs"
}

output "routing_rules" {
  value = {
    internet_to_firewall = azurerm_network_manager_routing_rule.internet_to_firewall.id
    private_via_firewall = azurerm_network_manager_routing_rule.private_via_firewall.id
  }
  description = "Map of Routing Rule IDs"
}
