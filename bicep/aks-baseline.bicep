@minLength(3)
param clusterName string

param location string = resourceGroup().location

@description('Resource ID de la subnet para los nodos de AKS')
param subnetId string

@description('Resource ID del Log Analytics workspace para diagnostics y Container Insights')
param logAnalyticsWorkspaceId string

@description('Object ID del grupo de Azure AD que será admin del cluster')
param aadAdminGroupObjectId string

@allowed(['Standard_DS2_v2', 'Standard_D4s_v5'])
param nodeVmSize string = 'Standard_D4s_v5'

param nodeCount int = 3

param kubernetesVersion string = '1.29'

resource aks 'Microsoft.ContainerService/managedClusters@2023-11-01' = {
  name: clusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: kubernetesVersion
    dnsPrefix: clusterName
    apiServerAccessProfile: {
      enablePrivateCluster: true
    }
    aadProfile: {
      managed: true
      enableAzureRBAC: true
      adminGroupObjectIDs: [
        aadAdminGroupObjectId
      ]
    }
    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'azure'
    }
    agentPoolProfiles: [
      {
        name: 'system'
        mode: 'System'
        count: nodeCount
        vmSize: nodeVmSize
        vnetSubnetID: subnetId
        osType: 'Linux'
      }
    ]
  }
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${clusterName}-diagnostics'
  scope: aks
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'kube-audit'
        enabled: true
      }
      {
        category: 'kube-apiserver'
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

output aksPrivateFqdn string = aks.properties.privateFQDN
output aksIdentityPrincipalId string = aks.identity.principalId
