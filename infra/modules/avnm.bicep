targetScope = 'resourceGroup'

param location string
param tags object
param avnmName string
param hubVnetId string
param subscriptionId string

resource networkManager 'Microsoft.Network/networkManagers@2023-11-01' = {
  name: avnmName
  location: location
  tags: tags
  properties: {
    networkManagerScopes: {
      subscriptions: ['/subscriptions/${subscriptionId}']
    }
    networkManagerScopeAccesses: ['Connectivity', 'SecurityAdmin']
    description: 'example network manager'
  }
}

resource networkGroup 'Microsoft.Network/networkManagers/networkGroups@2023-11-01' = {
  name: 'hub-spoke'
  parent: networkManager
  properties: {}
}

resource connectivityConfig 'Microsoft.Network/networkManagers/connectivityConfigurations@2023-11-01' = {
  name: 'connectivity-conf'
  parent: networkManager
  properties: {
    connectivityTopology: 'HubAndSpoke'
    appliesToGroups: [
      {
        groupConnectivity: 'None'
        networkGroupId: networkGroup.id
        isGlobal: 'False'
        useHubGateway: 'False'
      }
    ]
    hubs: [
      {
        resourceId: hubVnetId
        resourceType: 'Microsoft.Network/virtualNetworks'
      }
    ]
    deleteExistingPeering: 'False'
    isGlobal: 'False'
  }
}
