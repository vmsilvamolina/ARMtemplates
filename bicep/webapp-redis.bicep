import { allMetrics } from 'modules/diagnostics.bicep'

@minLength(2)
param appName string

@description('SKU del App Service Plan')
param appServicePlanSku string = 'S1'

param location string = resourceGroup().location

@allowed(['Basic', 'Standard', 'Premium'])
param redisSku string = 'Standard'

param redisCapacity int = 1

@description('Resource ID del Log Analytics workspace (opcional, vacío = sin diagnostics)')
param logAnalyticsWorkspaceId string = ''

var appServicePlanName = 'AppServicePlan-${appName}'
var webAppName = '${appName}-webapp'
var redisName = '${appName}-redis'
var keyVaultName = take('${appName}-kv', 24)

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  kind: 'app'
  sku: {
    name: appServicePlanSku
  }
}

resource redisCache 'Microsoft.Cache/redis@2023-08-01' = {
  name: redisName
  location: location
  properties: {
    sku: {
      name: redisSku
      family: redisSku == 'Premium' ? 'P' : 'C'
      capacity: redisCapacity
    }
    minimumTlsVersion: '1.2'
  }
}

module keyVault 'modules/key-vault.bicep' = {
  name: '${appName}-kv-deploy'
  params: {
    keyVaultName: keyVaultName
    location: location
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}

resource keyVaultExisting 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource redisSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVaultExisting
  name: 'redis-primary-key'
  properties: {
    value: redisCache.listKeys().primaryKey
  }
  dependsOn: [
    keyVault
  ]
}

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  kind: 'app'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    clientAffinityEnabled: false
    siteConfig: {
      minTlsVersion: '1.2'
      ftpsState: 'FtpsOnly'
      appSettings: [
        {
          name: 'Redis__InstanceName'
          value: redisName
        }
        {
          name: 'Redis__ConnectionString'
          value: '@Microsoft.KeyVault(SecretUri=${redisSecret.properties.secretUri})'
        }
      ]
    }
  }
}

resource kvSecretsUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVaultExisting.id, webApp.id, 'KeyVaultSecretsUser')
  scope: keyVaultExisting
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: webApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    keyVault
  ]
}

resource redisDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: '${redisName}-diagnostics'
  scope: redisCache
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    metrics: allMetrics
  }
}

output webAppHostName string = webApp.properties.defaultHostName
output keyVaultUri string = keyVault.outputs.keyVaultUri
