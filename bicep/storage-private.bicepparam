using './storage-private.bicep'

param storageAccountName = 'myappstore01'
// Resource IDs reales de una VNet/subnet ya existente donde cae el private endpoint.
param subnetId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworks/app-vnet/subnets/pe-subnet'
param vnetId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworks/app-vnet'
