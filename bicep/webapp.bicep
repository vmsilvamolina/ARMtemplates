@minLength(2)
@description('Nombre base del recurso webapp')
param webAppName string

@description('SKU del App Service Plan')
param sku string = 'S1'

@description('Ubicación de los recursos')
param location string = resourceGroup().location

@description('Resource ID del Log Analytics workspace (opcional, vacío = sin diagnostics)')
param logAnalyticsWorkspaceId string = ''

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

resource webAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: '${webAppPortalName}-diagnostics'
  scope: webApp
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output webAppHostName string = webApp.properties.defaultHostName
