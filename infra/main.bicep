targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the AZD environment (used to name the resource group).')
param environmentName string

@minLength(1)
@description('Azure region for all resources.')
param location string

@description('Hub VNet name.')
param vnetNameHub string = 'vnet-avnm-hub'

@description('Hub VNet address space.')
param addressSpaceHub string = '10.1.0.0/16'

@description('Azure Firewall subnet address prefix.')
param subnetSpaceFw string = '10.1.1.0/24'

@description('Spoke VNet configurations. Each entry needs name, addressSpace, and subnetSpace.')
param spokes array = [
  { name: 'vnet-avnm-spoke1', addressSpace: '10.2.0.0/24', subnetSpace: '10.2.0.0/27' }
  { name: 'vnet-avnm-spoke2', addressSpace: '10.3.0.0/24', subnetSpace: '10.3.0.0/27' }
  { name: 'vnet-avnm-spoke3', addressSpace: '10.4.0.0/24', subnetSpace: '10.4.0.0/27' }
]

@description('Azure Virtual Network Manager name.')
param avnmName string = 'avnm-demo'

@secure()
@description('Admin password for the Linux VMs. Set via: azd env set AZURE_VM_ADMIN_PASSWORD <password>')
param adminPassword string

var tags = {
  'azd-env-name': environmentName
}

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}

module hubSpokeLz './modules/hub-spoke-lz.bicep' = {
  name: 'hub-spoke-lz'
  scope: rg
  params: {
    location: location
    tags: tags
    vnetNameHub: vnetNameHub
    addressSpaceHub: addressSpaceHub
    subnetSpaceFw: subnetSpaceFw
    spokes: spokes
  }
}

module compute './modules/compute.bicep' = {
  name: 'compute'
  scope: rg
  params: {
    location: location
    tags: tags
    spokes: spokes
    spokeSubnetIds: hubSpokeLz.outputs.spokeSubnetIds
    adminPassword: adminPassword
  }
}

module avnm './modules/avnm.bicep' = {
  name: 'avnm'
  scope: rg
  params: {
    location: location
    tags: tags
    avnmName: avnmName
    hubVnetId: hubSpokeLz.outputs.hubVnetId
    subscriptionId: subscription().subscriptionId
  }
  dependsOn: [compute]
}

output AZURE_RESOURCE_GROUP string = rg.name
output AZURE_LOCATION string = location
