# Login to Azure
Login-AzureRmAccount

# Resource Group
$rg = "myappinfra-rg"
New-AzureRmResourceGroup -Name $rg -Location westeurope

# Deploy via Resource Group Deployment (replace with the correct name of template and parameters file)
New-AzureRmResourceGroupDeployment -ResourceGroupName $rg -Mode Complete -TemplateFile ".\azuredeploy.json" -TemplateParameterFile ".\azuredeploy.parameters.json"