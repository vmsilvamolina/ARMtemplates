using './firewall-hub-spoke.bicep'

param namePrefix = 'hubspoke'
param hubVnetAddressPrefix = '10.0.0.0/16'
param hubFirewallSubnetPrefix = '10.0.0.0/26'
param spokeVnetAddressPrefix = '10.1.0.0/16'
param spokeWorkloadSubnetPrefix = '10.1.0.0/24'
