using './aks-baseline.bicep'

param clusterName = 'myapp-aks'
param subnetId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworks/app-vnet/subnets/aks-subnet'
param logAnalyticsWorkspaceId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/observability-rg/providers/Microsoft.OperationalInsights/workspaces/shared-law'
// Grupo de Entra ID con rol admin sobre el cluster vía Azure RBAC.
param aadAdminGroupObjectId = '00000000-0000-0000-0000-000000000000'
param nodeVmSize = 'Standard_D4s_v5'
param nodeCount = 3
param kubernetesVersion = '1.29'
