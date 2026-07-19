@description('Nombre del logical SQL server')
param sqlServerName string

@description('Nombre de la base de datos')
param databaseName string

param location string = resourceGroup().location

@description('Object ID del admin de Azure AD (usuario o grupo)')
param aadAdminObjectId string

@description('Nombre del admin de Azure AD')
param aadAdminLogin string

@description('Resource ID de la subnet donde se despliega el private endpoint')
param subnetId string

@description('Resource ID de la VNet (para linkear la private DNS zone)')
param vnetId string

@allowed(['Basic', 'S0', 'S1', 'GP_Gen5_2'])
param skuName string = 'S0'

resource sqlServer 'Microsoft.Sql/servers@2023-08-01' = {
  name: sqlServerName
  location: location
  properties: {
    administrators: {
      administratorType: 'ActiveDirectory'
      principalType: 'User'
      login: aadAdminLogin
      sid: aadAdminObjectId
      azureADOnlyAuthentication: true
    }
    publicNetworkAccess: 'Disabled'
    minimalTlsVersion: '1.2'
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-08-01' = {
  parent: sqlServer
  name: databaseName
  location: location
  sku: {
    name: skuName
  }
}

module privateEndpoint 'modules/private-endpoint.bicep' = {
  name: '${sqlServerName}-pe-deploy'
  params: {
    privateEndpointName: '${sqlServerName}-sql-pe'
    location: location
    targetResourceId: sqlServer.id
    groupId: 'sqlServer'
    subnetId: subnetId
    privateDnsZoneName: 'privatelink${environment().suffixes.sqlServerHostname}'
    vnetId: vnetId
  }
}

output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
