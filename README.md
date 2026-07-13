# ARMtemplates

Ejemplos de infraestructura Azure, migrados de ARM JSON a Bicep.

Originalmente un grab-bag de templates ARM (2018-2019). Retomado en 2026 para
modernizar a Bicep y aplicar hardening de seguridad sobre cada patrón — Key
Vault en vez de secretos en texto plano, origin lock-down en Front Door, NSGs
restringidas en vez de abiertas a Internet.

## Estado

🚧 Migración en curso.

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

## Deploy

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
