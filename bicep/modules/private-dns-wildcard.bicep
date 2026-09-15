// Private DNS zone con un registro wildcard (*) a una IP privada, linkeada a una VNet.
// Para dominios que solo se conocen en runtime (ej: defaultDomain de un
// Container Apps environment interno): como parámetro de módulo, el nombre
// de la zona puede salir del output de otro recurso.

@description('Nombre de la private DNS zone')
param zoneName string

@description('IP privada a la que apunta el wildcard')
param ipAddress string

@description('Resource ID de la VNet a linkear con la zona')
param vnetId string

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: zoneName
  location: 'global'
}

resource wildcardRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: privateDnsZone
  name: '*'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: ipAddress
      }
    ]
  }
}

resource dnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: '${zoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

output privateDnsZoneId string = privateDnsZone.id
