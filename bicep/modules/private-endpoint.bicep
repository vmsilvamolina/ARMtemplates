@description('Nombre del private endpoint')
param privateEndpointName string

param location string = resourceGroup().location

@description('Resource ID del recurso al que se conecta (storage account, sql server, etc.)')
param targetResourceId string

@description('Sub-resource / group id del private link (ej: blob, sqlServer)')
param groupId string

@description('Resource ID de la subnet donde se despliega el private endpoint')
param subnetId string

@description('Nombre de la private DNS zone (ej: privatelink.blob.core.windows.net)')
param privateDnsZoneName string

@description('Resource ID de la VNet a linkear con la private DNS zone')
param vnetId string

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${privateEndpointName}-connection'
        properties: {
          privateLinkServiceId: targetResourceId
          groupIds: [
            groupId
          ]
        }
      }
    ]
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
}

resource dnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: '${privateDnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource dnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-09-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

output privateEndpointId string = privateEndpoint.id
