# Login to Azure
Login-AzAccount

# Resource Group
$rg = "myappinfra-rg"
New-AzResourceGroup -Name $rg -Location westeurope

# Deploy via Resource Group Deployment (replace with the correct name of template and parameters file)
New-AzResourceGroupDeployment -ResourceGroupName $rg -Mode Complete -TemplateFile ".\azuredeploy.json" -TemplateParameterFile ".\azuredeploy.parameters.json"