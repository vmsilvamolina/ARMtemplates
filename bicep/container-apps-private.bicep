import { allMetrics, logsEnabled } from 'modules/diagnostics.bicep'

@minLength(2)
@maxLength(20)
@description('Nombre base de los recursos')
param appName string

param location string = resourceGroup().location

@description('Resource ID de la subnet de infraestructura del environment. Debe estar delegada a Microsoft.App/environments y ser /27 o mayor')
param infrastructureSubnetId string

@description('Resource ID de la subnet donde se despliega el private endpoint del ACR')
param privateEndpointSubnetId string

@description('Resource ID de la VNet (para linkear las private DNS zones)')
param vnetId string

@description('Imagen del contenedor. Para imágenes del ACR privado: <acr>.azurecr.io/<repo>:<tag>')
param containerImage string = 'mcr.microsoft.com/k8se/quickstart:latest'

@description('Puerto en el que escucha el contenedor')
param targetPort int = 80

@description('Path HTTP para los probes de liveness y readiness')
param healthProbePath string = '/'

@description('CIDRs con acceso al ingress de la app (ej: subnets de los consumidores). Vacío = toda la VNet')
param allowedIngressCidrs string[] = []

@description('Reparte el environment entre availability zones (sin costo extra; la región tiene que soportar AZ)')
param zoneRedundant bool = true

@minValue(1)
param minReplicas int = 2

param maxReplicas int = 5

@description('Resource ID del Log Analytics workspace (opcional, vacío = sin diagnostics)')
param logAnalyticsWorkspaceId string = ''

var environmentName = '${appName}-cae'
var containerAppName = '${appName}-app'
var identityName = '${appName}-id'
// Nombre global del ACR: solo alfanumérico, 5-50 caracteres.
var acrName = take('${replace(appName, '-', '')}${uniqueString(resourceGroup().id)}', 50)

// User-assigned y no system-assigned: la identidad tiene que existir y tener
// AcrPull ANTES de crear la container app, si no el primer pull de la imagen
// falla. Con system-assigned la identidad nace junto con la app (huevo y gallina).
resource pullIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
}

// Premium es el único SKU con private endpoint.
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Premium'
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Disabled'
    networkRuleBypassOptions: 'None'
    zoneRedundancy: 'Disabled'
    policies: {
      retentionPolicy: {
        status: 'enabled'
        days: 7
      }
      exportPolicy: {
        status: 'disabled'
      }
    }
  }
}

resource acrPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, pullIdentity.id, 'AcrPull')
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    principalId: pullIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

module acrPrivateEndpoint 'modules/private-endpoint.bicep' = {
  name: '${appName}-acr-pe-deploy'
  params: {
    privateEndpointName: '${acrName}-pe'
    location: location
    targetResourceId: acr.id
    groupId: 'registry'
    subnetId: privateEndpointSubnetId
    privateDnsZoneName: 'privatelink${environment().suffixes.acrLoginServer}'
    vnetId: vnetId
  }
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: environmentName
  location: location
  properties: {
    vnetConfiguration: {
      infrastructureSubnetId: infrastructureSubnetId
      // Environment interno: sin IP pública, solo alcanzable desde la VNet.
      internal: true
    }
    zoneRedundant: zoneRedundant
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
    // Con 'azure-monitor' los logs salen por el diagnostic setting de abajo.
    appLogsConfiguration: empty(logAnalyticsWorkspaceId) ? null : {
      destination: 'azure-monitor'
    }
  }
}

// Un environment interno no publica DNS: sin esta zona, los clientes de la VNet
// no resuelven <app>.<defaultDomain>. Wildcard al static IP del ILB del environment.
module environmentDns 'modules/private-dns-wildcard.bicep' = {
  name: '${appName}-cae-dns-deploy'
  params: {
    zoneName: containerAppsEnvironment.properties.defaultDomain
    ipAddress: containerAppsEnvironment.properties.staticIp
    vnetId: vnetId
  }
}

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${pullIdentity.id}': {}
    }
  }
  properties: {
    environmentId: containerAppsEnvironment.id
    workloadProfileName: 'Consumption'
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        // external dentro de un environment interno = visible para la VNet, no para Internet.
        external: true
        targetPort: targetPort
        transport: 'auto'
        allowInsecure: false
        stickySessions: {
          affinity: 'none'
        }
        ipSecurityRestrictions: [for (cidr, i) in allowedIngressCidrs: {
          name: 'allow-${i}'
          action: 'Allow'
          ipAddressRange: cidr
        }]
      }
      // Pull del ACR con la managed identity, sin usuario admin ni password.
      registries: [
        {
          server: acr.properties.loginServer
          identity: pullIdentity.id
        }
      ]
    }
    template: {
      containers: [
        {
          name: containerAppName
          image: containerImage
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: healthProbePath
                port: targetPort
              }
            }
            {
              type: 'Readiness'
              httpGet: {
                path: healthProbePath
                port: targetPort
              }
            }
          ]
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
      }
    }
  }
  dependsOn: [
    acrPullRole
    acrPrivateEndpoint
  ]
}

resource environmentDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: '${environmentName}-diagnostics'
  scope: containerAppsEnvironment
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: logsEnabled([
      'ContainerAppConsoleLogs'
      'ContainerAppSystemLogs'
    ])
    metrics: allMetrics
  }
}

resource acrDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: '${acrName}-diagnostics'
  scope: acr
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: logsEnabled([
      'ContainerRegistryRepositoryEvents'
      'ContainerRegistryLoginEvents'
    ])
    metrics: allMetrics
  }
}

output containerAppFqdn string = containerApp.properties.configuration.ingress.fqdn
output environmentStaticIp string = containerAppsEnvironment.properties.staticIp
output acrLoginServer string = acr.properties.loginServer
