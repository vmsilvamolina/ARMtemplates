// Definiciones compartidas para diagnostic settings.
// Uso desde un template en bicep/:
//   import { allMetrics, logsEnabled } from 'modules/diagnostics.bicep'
// Uso desde otro módulo en esta carpeta:
//   import { allMetrics, logsEnabled } from 'diagnostics.bicep'

@export()
@description('Entrada de categoría para el bloque logs o metrics de un diagnostic setting')
type diagnosticCategory = {
  category: string
  enabled: bool
}

@export()
@description('Bloque metrics más común: la categoría AllMetrics habilitada')
var allMetrics diagnosticCategory[] = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]

@export()
@description('Convierte una lista de nombres de categoría de log en entradas habilitadas')
func logsEnabled(categories string[]) diagnosticCategory[] => map(categories, category => {
  category: category
  enabled: true
})
