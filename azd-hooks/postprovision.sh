#!/bin/bash

echo  "Building openai-aca-lb:latest..."
az acr build --subscription ${AZURE_SUBSCRIPTION_ID} --registry ${AZURE_REGISTRY_NAME} --image openai-aca-lb:latest ./src/
image_name="${AZURE_REGISTRY_NAME}.azurecr.io/openai-aca-lb:latest"
az containerapp update --subscription ${AZURE_SUBSCRIPTION_ID} --name ${SERVICE_WEB_NAME} --resource-group ${RESOURCE_GROUP_NAME} --image ${image_name}
