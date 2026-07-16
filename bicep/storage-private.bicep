@minLength(3)
@maxLength(24)
param storageAccountName string

param location string = resourceGroup().location

@description('Resource ID de la subnet donde se despliega el private endpoint')
param subnetId string

@description('Resource ID de la VNet (para linkear la private DNS zone)')
param vnetId string

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
    }
  }
}

module privateEndpoint 'modules/private-endpoint.bicep' = {
  name: '${storageAccountName}-pe-deploy'
  params: {
    privateEndpointName: '${storageAccountName}-blob-pe'
    location: location
    targetResourceId: storageAccount.id
    groupId: 'blob'
    subnetId: subnetId
    privateDnsZoneName: 'privatelink.blob.${environment().suffixes.storage}'
    vnetId: vnetId
  }
}

output storageAccountId string = storageAccount.id
