@description('Nombre del Log Analytics workspace')
param workspaceName string

param location string = resourceGroup().location

@description('Días de retención de logs')
param retentionInDays int = 30

@allowed(['Free', 'PerGB2018'])
param sku string = 'PerGB2018'

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: retentionInDays
  }
}

output workspaceId string = workspace.id
output workspaceName string = workspace.name
