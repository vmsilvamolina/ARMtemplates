using './sql-private.bicep'

param sqlServerName = 'myapp-sql01'
param databaseName = 'appdb'
// Object ID y nombre del usuario o grupo de Entra ID que administra el server.
param aadAdminObjectId = '00000000-0000-0000-0000-000000000000'
param aadAdminLogin = 'sql-admins@contoso.com'
param subnetId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworks/app-vnet/subnets/pe-subnet'
param vnetId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworks/app-vnet'
param skuName = 'S0'
