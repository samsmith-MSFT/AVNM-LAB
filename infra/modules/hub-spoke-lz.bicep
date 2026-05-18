targetScope = 'resourceGroup'

param location string
param tags object
param vnetNameHub string
param addressSpaceHub string
param subnetSpaceFw string
param spokes array

// Public IP for Azure Firewall
resource firewallPip 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: 'firewall-ip'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Hub VNet
resource hubVnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetNameHub
  location: location
  tags: union(tags, { environment: 'hub' })
  properties: {
    addressSpace: {
      addressPrefixes: [addressSpaceHub]
    }
  }
}

// Azure Firewall subnet — must be named exactly 'AzureFirewallSubnet'
resource hubFwSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  name: 'AzureFirewallSubnet'
  parent: hubVnet
  properties: {
    addressPrefix: subnetSpaceFw
  }
}

// Firewall Policy
resource firewallPolicy 'Microsoft.Network/firewallPolicies@2023-11-01' = {
  name: 'azfw-hub-policy'
  location: location
  tags: tags
  properties: {
    sku: {
      tier: 'Standard'
    }
  }
}

// Allow all RFC1918 → RFC1918 traffic through the firewall
resource ruleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-11-01' = {
  name: 'demo-fwpolicy-rcg'
  parent: firewallPolicy
  properties: {
    priority: 500
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'network_rule_collection1'
        priority: 400
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'network_rule_collection1_rule1'
            ipProtocols: ['TCP', 'UDP', 'ICMP']
            sourceAddresses: ['10.0.0.0/8']
            destinationAddresses: ['10.0.0.0/8']
            destinationPorts: ['*']
          }
        ]
      }
    ]
  }
}

// Azure Firewall
resource firewall 'Microsoft.Network/azureFirewalls@2023-11-01' = {
  name: 'azfw-hub'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    firewallPolicy: {
      id: firewallPolicy.id
    }
    ipConfigurations: [
      {
        name: 'FirewallIpConfig'
        properties: {
          subnet: {
            id: hubFwSubnet.id
          }
          publicIPAddress: {
            id: firewallPip.id
          }
        }
      }
    ]
  }
}

// Route table — forces all spoke traffic through the firewall
resource routeTable 'Microsoft.Network/routeTables@2023-11-01' = {
  name: 'avnm-route-table'
  location: location
  tags: tags
  properties: {
    disableBgpRoutePropagation: true
    routes: [
      {
        name: 'default-route'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewall.properties.ipConfigurations[0].properties.privateIPAddress
        }
      }
    ]
  }
}

// Spoke VNets
resource spokeVnets 'Microsoft.Network/virtualNetworks@2023-11-01' = [for spoke in spokes: {
  name: spoke.name
  location: location
  tags: union(tags, { environment: 'spoke' })
  properties: {
    addressSpace: {
      addressPrefixes: [spoke.addressSpace]
    }
  }
}]

// Spoke subnets — each associated with the route table
resource spokeSubnets 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = [for (spoke, i) in spokes: {
  name: '${spoke.name}-subnet'
  parent: spokeVnets[i]
  properties: {
    addressPrefix: spoke.subnetSpace
    routeTable: {
      id: routeTable.id
    }
  }
}]

output hubVnetId string = hubVnet.id
output spokeSubnetIds array = [for (spoke, i) in spokes: spokeSubnets[i].id]
