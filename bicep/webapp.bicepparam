using './webapp.bicep'

param webAppName = 'myapp'
param sku = 'S1'
// Vacío = sin diagnostics. Poner el resource ID del Log Analytics workspace
// para mandar logs/métricas al workspace compartido.
param logAnalyticsWorkspaceId = ''
