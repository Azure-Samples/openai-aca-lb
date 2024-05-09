#!/usr/bin/env pwsh

Write-Output  "Building openai-aca-lb:latest..."
az acr build --subscription $env:AZURE_SUBSCRIPTION_ID --registry $env:AZURE_REGISTRY_NAME --image openai-aca-lb:latest ./src/
$image_name = $env:AZURE_REGISTRY_NAME + '.azurecr.io/openai-aca-lb:latest'
az containerapp update --subscription $env:AZURE_SUBSCRIPTION_ID --name $env:SERVICE_WEB_NAME --resource-group $env:RESOURCE_GROUP_NAME --image $image_name