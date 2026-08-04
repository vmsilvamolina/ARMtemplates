# Changelog

## [Unreleased]

### Changed

- Migración completa de ARM JSON a Bicep para los 4 templates del repo.
- `webapp-redis`: reemplazo de claves en texto plano por Key Vault + managed identity.
- `webapp-frontdoor`: migración de Front Door classic a Front Door Premium + WAF, origin lock-down.
- `jenkins`: NSG restringida, autenticación solo por SSH key, sin dependencias de marketplace externo.
- `webapp.bicep`, `webapp-redis.bicep`, `jenkins.bicep` ahora aceptan `logAnalyticsWorkspaceId` opcional para diagnostics.

### Added

- `bicep/` con los 4 templates migrados.
- `.github/workflows/` con build y security scan (PSRule.Rules.Azure).
- `bicepconfig.json` con analyzers de seguridad habilitados.
- `bicep/modules/log-analytics.bicep` y `bicep/modules/private-endpoint.bicep` — módulos reusables.
- `bicep/storage-private.bicep` y `bicep/sql-private.bicep` — recursos sin acceso público, solo private endpoint.
- `bicep/firewall-hub-spoke.bicep` — companion IaC del post "Azure Firewall vs NSGs".
- `bicep/aks-baseline.bicep` — AKS privado con Entra ID + Azure RBAC.

### Kept

- ARM JSON originales, como referencia histórica.
En el mismo commit, en README.md, cambiar la línea de "Estado":
🚧 Migración en curso. Ver [CHANGELOG](./CHANGELOG.md).
