@minLength(2)
@description('Nombre base del recurso webapp')
param webAppName string

@description('SKU del App Service Plan')
param sku string = 'S1'

@description('Ubicación de los recursos')
param location string = resourceGroup().location

var webAppPortalName = '${webAppName}-webapp'
var appServicePlanName = 'AppServicePlan-${webAppName}'

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  kind: 'app'
  sku: {
    name: sku
  }
}

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppPortalName
  location: location
  kind: 'app'
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      minTlsVersion: '1.2'
      ftpsState: 'FtpsOnly'
    }
  }
}

output webAppHostName string = webApp.properties.defaultHostName