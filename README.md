# ARMtemplates

![Bicep Build](https://github.com/vmsilvamolina/ARMtemplates/actions/workflows/bicep-build.yml/badge.svg)
![Security Scan](https://github.com/vmsilvamolina/ARMtemplates/actions/workflows/security-scan.yml/badge.svg)

Ejemplos de infraestructura Azure, migrados de ARM JSON a Bicep.

Originalmente un grab-bag de templates ARM (2018-2019). Retomado en 2026 para
modernizar a Bicep y aplicar hardening de seguridad sobre cada patrón — Key
Vault en vez de secretos en texto plano, origin lock-down en Front Door, NSGs
restringidas en vez de abiertas a Internet.

## Estado

Migración de ARM JSON a Bicep completa para los cuatro patrones originales
(`webapp`, `webapp-redis`, `webapp-frontdoor`, `jenkins`). El repo sigue
creciendo con patrones nuevos de networking, datos y AKS. Ver
[CHANGELOG](./CHANGELOG.md).

## Arquitectura

Cuatro patrones de infraestructura, cada uno migrado de ARM JSON a Bicep:

- **`webapp.bicep`** — App Service Plan + Web App mínimo (baseline).
- **`webapp-redis.bicep`** — Web App + Azure Cache for Redis, secretos vía Key
  Vault + managed identity (sin claves en texto plano).
- **`webapp-frontdoor.bicep`** — Web App detrás de Front Door Premium + WAF,
  origin bloqueado a tráfico directo (solo acepta requests con el header
  `X-Azure-FDID` de Front Door).
- **`jenkins.bicep`** — VM Jenkins hardened: solo SSH por clave, NSG
  restringida a un CIDR conocido, sin templates de marketplace externos.

Los ARM JSON originales quedan en la raíz del repo como referencia histórica.

### Networking y datos (nuevo)

- **`bicep/modules/log-analytics.bicep`** — módulo reusable: Log Analytics workspace para diagnostics.
- **`bicep/modules/private-endpoint.bicep`** — módulo reusable: private endpoint + private DNS zone, usado por storage y SQL.
- **`bicep/storage-private.bicep`** — Storage Account sin acceso público, solo vía private endpoint.
- **`bicep/sql-private.bicep`** — Azure SQL con Azure AD-only auth (sin SQL login) + private endpoint. Reemplaza el patrón de connection string en texto plano del `webapp-redis.json` original.
- **`bicep/firewall-hub-spoke.bicep`** — hub-spoke con Azure Firewall, companion IaC del post de Azure Firewall vs NSGs (ver sección Seguridad).
- **`bicep/aks-baseline.bicep`** — AKS privado, Entra ID + Azure RBAC, network policy, diagnostics a Log Analytics.

Los templates existentes (`webapp`, `webapp-redis`, `jenkins`) ahora aceptan un parámetro opcional `logAnalyticsWorkspaceId` para mandar sus logs/métricas al mismo workspace.

## Deploy

Cada template tiene un archivo de parámetros de ejemplo en
`bicep/<template>.bicepparam` (nombres, CIDRs y resource IDs de placeholder).
Editarlos antes de desplegar y después correr:

```powershell
./PowerShellDeployExample.ps1
```

## Seguridad

Cada template resuelve un anti-patrón puntual del original:

| Template | Antes (ARM) | Ahora (Bicep) |
| --- | --- | --- |
| webapp-redis | Redis key y connection string embebidos en `appsettings` | Key Vault + `SystemAssigned` managed identity + RBAC (`Key Vault Secrets User`) |
| webapp-frontdoor | Origin accesible directo, bypassing Front Door | `ipSecurityRestrictions` + validación de header `X-Azure-FDID`, WAF en modo Prevention |
| jenkins | NSG abierta a `Internet` en SSH/HTTP, password auth | NSG restringida a CIDR conocido, `disablePasswordAuthentication: true` |

### Companion IaC: Azure Firewall vs NSGs

`bicep/firewall-hub-spoke.bicep` es el IaC del post [Azure Firewall vs NSGs: A Defense-in-Depth Security Model](https://blog.victorsilva.com.uy/azure-firewall-vs-nsg-hub-and-spoke/) — hub VNet con Azure Firewall, spoke peereado, y UDR forzando todo el egress del spoke a través del firewall. Sin esa ruta, el spoke sale directo a Internet y el firewall no ve nada.
