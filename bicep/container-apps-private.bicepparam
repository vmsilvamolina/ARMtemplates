using './container-apps-private.bicep'

param appName = 'myapp'
// Subnet /27 o mayor, delegada a Microsoft.App/environments y sin otros recursos.
param infrastructureSubnetId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworks/app-vnet/subnets/aca-subnet'
param privateEndpointSubnetId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworks/app-vnet/subnets/pe-subnet'
param vnetId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworks/app-vnet'
param containerImage = 'mcr.microsoft.com/k8se/quickstart:latest'
param targetPort = 80
// Solo los spokes/subnets que consumen la app. Vacío = cualquier origen de la VNet.
param allowedIngressCidrs = [
  '10.1.0.0/24'
]
param logAnalyticsWorkspaceId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/observability-rg/providers/Microsoft.OperationalInsights/workspaces/shared-law'
