# Connect to Azure
Connect-AzAccount

# Resource Group
$rg = "myappinfra-rg"
$location = "westeurope"
New-AzResourceGroup -Name $rg -Location $location -Force

# Baseline: App Service Plan + Web App
New-AzResourceGroupDeployment `
  -ResourceGroupName $rg `
  -TemplateFile ".\bicep\webapp.bicep" `
  -webAppName "myapp"

# Web App + Redis, secretos vía Key Vault + managed identity
New-AzResourceGroupDeployment `
  -ResourceGroupName $rg `
  -TemplateFile ".\bicep\webapp-redis.bicep" `
  -appName "myapp"

# Web App detrás de Front Door Premium + WAF, origin lock-down
New-AzResourceGroupDeployment `
  -ResourceGroupName $rg `
  -TemplateFile ".\bicep\webapp-frontdoor.bicep" `
  -appName "myapp" `
  -frontDoorEndpointPrefix "myapp-afd"

# Jenkins VM hardened: SSH key only, NSG restringida a tu IP
New-AzResourceGroupDeployment `
  -ResourceGroupName $rg `
  -TemplateFile ".\bicep\jenkins.bicep" `
  -adminSshPublicKey (Get-Content "$HOME\.ssh\id_rsa.pub" -Raw) `
  -allowedSshSourceCidr "<publicIP>/32"