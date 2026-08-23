// Módulo reusable: Azure Key Vault hardened.
//   - solo RBAC (sin access policies)
//   - soft-delete + purge protection
//   - firewall en Deny por defecto (Disabled si no hay reglas que permitir)
//   - diagnostics opcional al workspace compartido
//   - asigna Key Vault Secrets User a las identities que se le pasen

@minLength(3)
@maxLength(24)
@description('Nombre del Key Vault')
param keyVaultName string

param location string = resourceGroup().location

@allowed(['standard', 'premium'])
param skuName string = 'standard'

@minValue(7)
@maxValue(90)
@description('Días de retención de soft-delete')
param softDeleteRetentionInDays int = 90

@description('Purge protection: impide el borrado definitivo antes de la retención. No se puede desactivar una vez activo.')
param enablePurgeProtection bool = true

@allowed(['Allow', 'Deny'])
@description('Acción por defecto del firewall del vault')
param networkDefaultAction string = 'Deny'

@description('IPs o CIDRs permitidos cuando networkDefaultAction = Deny')
param allowedIpRules string[] = []

@description('Resource IDs de subnets permitidas cuando networkDefaultAction = Deny (necesitan el service endpoint Microsoft.KeyVault)')
param allowedSubnetIds string[] = []

@description('Principal IDs (managed identities) que reciben el rol Key Vault Secrets User sobre el vault')
param secretsUserPrincipalIds string[] = []

@description('Resource ID del Log Analytics workspace (vacío = sin diagnostics)')
param logAnalyticsWorkspaceId string = ''

import { allMetrics, logsEnabled } from 'diagnostics.bicep'

// Key Vault Secrets User
var keyVaultSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'
var lockDownPublicAccess = networkDefaultAction == 'Deny' && empty(allowedIpRules) && empty(allowedSubnetIds)

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: skuName
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enablePurgeProtection: enablePurgeProtection ? true : null
    publicNetworkAccess: lockDownPublicAccess ? 'Disabled' : 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: networkDefaultAction
      ipRules: map(allowedIpRules, ip => {
        value: ip
      })
      virtualNetworkRules: map(allowedSubnetIds, subnetId => {
        id: subnetId
      })
    }
  }
}

resource secretsUserRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for principalId in secretsUserPrincipalIds: {
    name: guid(keyVault.id, principalId, keyVaultSecretsUserRoleId)
    scope: keyVault
    properties: {
      roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUserRoleId)
      principalId: principalId
      principalType: 'ServicePrincipal'
    }
  }
]

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: '${keyVaultName}-diagnostics'
  scope: keyVault
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: logsEnabled([
      'AuditEvent'
      'AzurePolicyEvaluationDetails'
    ])
    metrics: allMetrics
  }
}

output keyVaultId string = keyVault.id
output keyVaultUri string = keyVault.properties.vaultUri
output keyVaultName string = keyVault.name
