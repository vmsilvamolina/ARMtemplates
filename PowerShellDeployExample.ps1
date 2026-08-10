# Connect to Azure
Connect-AzAccount

# Resource Group
$rg = "myappinfra-rg"
$location = "westeurope"
New-AzResourceGroup -Name $rg -Location $location -Force

# Cada template tiene un archivo de parámetros de ejemplo en bicep/<template>.bicepparam.
# Editar esos archivos (nombres, CIDRs, resource IDs) antes de desplegar.

# Baseline: App Service Plan + Web App
New-AzResourceGroupDeployment `
  -ResourceGroupName $rg `
  -TemplateFile ".\bicep\webapp.bicep" `
  -TemplateParameterFile ".\bicep\webapp.bicepparam"

# Web App + Redis, secretos vía Key Vault + managed identity
New-AzResourceGroupDeployment `
  -ResourceGroupName $rg `
  -TemplateFile ".\bicep\webapp-redis.bicep" `
  -TemplateParameterFile ".\bicep\webapp-redis.bicepparam"

# Web App detrás de Front Door Premium + WAF, origin lock-down
New-AzResourceGroupDeployment `
  -ResourceGroupName $rg `
  -TemplateFile ".\bicep\webapp-frontdoor.bicep" `
  -TemplateParameterFile ".\bicep\webapp-frontdoor.bicepparam"

# Jenkins VM hardened: SSH key only, NSG restringida a tu IP.
# Setear adminSshPublicKey y allowedSshSourceCidr en jenkins.bicepparam primero.
New-AzResourceGroupDeployment `
  -ResourceGroupName $rg `
  -TemplateFile ".\bicep\jenkins.bicep" `
  -TemplateParameterFile ".\bicep\jenkins.bicepparam"
