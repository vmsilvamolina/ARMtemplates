# Changelog

## [Unreleased]

### Changed

- Migración completa de ARM JSON a Bicep para los 4 templates del repo.
- `webapp-redis`: reemplazo de claves en texto plano por Key Vault + managed identity.
- `webapp-redis`: el Key Vault inline se reemplaza por el módulo `key-vault.bicep` (agrega `softDeleteRetentionInDays`, purge protection y diagnostics del vault).
- `webapp-frontdoor`: migración de Front Door classic a Front Door Premium + WAF, origin lock-down.
- `jenkins`: NSG restringida, autenticación solo por SSH key, sin dependencias de marketplace externo.
- `webapp.bicep`, `webapp-redis.bicep`, `jenkins.bicep` ahora aceptan `logAnalyticsWorkspaceId` opcional para diagnostics.
- `webapp`, `jenkins`, `aks-baseline`: los diagnostic settings arman sus listas de categorías con `logsEnabled(...)` / `allMetrics` importados de `modules/diagnostics.bicep` en vez de repetir los bloques inline.
- `sql-private`: Microsoft Defender for SQL + vulnerability assessment (sin storage account) + auditing hacia Azure Monitor.
- `storage-private`: SKU `Standard_ZRS`, `allowSharedKeyAccess: false`, soft-delete de blobs y contenedores (7 días).
- `webapp`, `webapp-frontdoor`: managed identity `SystemAssigned`, `clientAffinityEnabled: false`, `alwaysOn`, `http20Enabled`, `healthCheckPath: /health`.
- `webapp-redis`: `alwaysOn`, `http20Enabled`, `healthCheckPath: /health`.
- `jenkins`: regla NSG que deniega salida SSH/RDP hacia el resto de la VNet (anti movimiento lateral), `defaultOutboundAccess: false` en la subnet, `caching: ReadWrite` en el disco.
- `ps-rule.yaml`: config de PSRule.Rules.Azure — excluye reglas de costo/tier/tags fuera del alcance de estos templates de demo; documenta el criterio en el propio archivo.

### Added

- `bicep/` con los 4 templates migrados.
- `.github/workflows/` con build y security scan (PSRule.Rules.Azure).
- `.github/workflows/bicep-whatif.yml` — `az deployment group what-if` de cada template contra un RG real, auth por OIDC (sin secretos), resultado en el Step Summary del PR.
- `bicepconfig.json` con analyzers de seguridad habilitados.
- `bicep/modules/log-analytics.bicep` y `bicep/modules/private-endpoint.bicep` — módulos reusables.
- `bicep/modules/diagnostics.bicep` — tipo `diagnosticCategory` y función `logsEnabled` compartidos vía `import` de compile-time.
- `bicep/modules/key-vault.bicep` — módulo reusable de Key Vault hardened (RBAC-only, soft-delete + purge protection, firewall en Deny), consumido por `webapp-redis`.
- `bicep/storage-private.bicep` y `bicep/sql-private.bicep` — recursos sin acceso público, solo private endpoint.
- `bicep/firewall-hub-spoke.bicep` — companion IaC del post "Azure Firewall vs NSGs".
- `bicep/aks-baseline.bicep` — AKS privado con Entra ID + Azure RBAC.
- `bicep/*.bicepparam` — archivo de parámetros de ejemplo por template, usado por `PowerShellDeployExample.ps1`.

### Fixed

- `bicep-build.yml`: el workflow ahora también buildea `bicep/modules/*.bicep` y valida los `*.bicepparam`.

### Kept

- ARM JSON originales, como referencia histórica.
