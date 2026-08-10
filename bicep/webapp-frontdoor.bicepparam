using './webapp-frontdoor.bicep'

param appName = 'myapp'
// Debe ser único a nivel global: forma parte del hostname de Front Door.
param frontDoorEndpointPrefix = 'myapp-afd'
param frontDoorSku = 'Premium_AzureFrontDoor'
