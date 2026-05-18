targetScope = 'resourceGroup'

param location string
param tags object
param spokes array
param spokeSubnetIds array

@secure()
param adminPassword string

var adminUsername = 'azureadmin'

resource nics 'Microsoft.Network/networkInterfaces@2023-11-01' = [for (spoke, i) in spokes: {
  name: '${spoke.name}-nic'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'internal'
        properties: {
          subnet: {
            id: spokeSubnetIds[i]
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}]

resource vms 'Microsoft.Compute/virtualMachines@2024-03-01' = [for (spoke, i) in spokes: {
  name: '${spoke.name}-vm'
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2ls_v2'
    }
    storageProfile: {
      osDisk: {
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
        createOption: 'FromImage'
      }
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
    }
    osProfile: {
      computerName: '${spoke.name}-vm'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nics[i].id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}]
