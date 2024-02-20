param name string
param location string = resourceGroup().location
param tags object = {}

param applicationInsightsName string
param containerAppsEnvironmentName string
param containerRegistryName string
param identityName string
param identityClientId string
param logAnalyticsWorkspaceName string

@minLength(1)
@description('The URL of your first Azure OpenAI endpoint in the following format: https://[name].openai.azure.com')
param backend_1_url string

@description('The priority of your first OpenAI endpoint (lower number means higher priority)')
param backend_1_priority int

@minLength(1)
@description('The URL of your second Azure OpenAI endpoint in the following format: https://[name].openai.azure.com')
param backend_2_url string

@description('The priority of your second OpenAI endpoint (lower number means higher priority)')
param backend_2_priority int

@minLength(1)
@description('The URL of your second Azure OpenAI endpoint in the following format: https://[name].openai.azure.com')
param backend_3_url string

@description('The priority of your second OpenAI endpoint (lower number means higher priority)')
param backend_3_priority int


// module containerAppsEnvironment 'core/host/container-apps-environment.bicep' = {
//   name: containerAppsEnvironmentName
//   params: {
//     name: containerAppsEnvironmentName
//     location: location
//     tags: tags
//     logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
//     applicationInsightsName: applicationInsightsName
//   }
// }

// module containerRegistry 'core/host/container-registry.bicep' = {
//   name: containerRegistryName
//   params: {
//     name: containerRegistryName
//     location: location
//     tags: tags
//   }
// }

// Container apps host (including container registry)
module containerApps 'core/host/container-apps.bicep' = {
  name: 'container-apps'
  params: {
    name: 'app'
    location: location
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerRegistryName: containerRegistryName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  }
}

module app 'core/host/container-app.bicep' = {
  name: '${deployment().name}-update'
  params: {
    name: name
    location: location
    tags: tags
    identityName: identityName
    ingressEnabled: true
    containerName: 'main'
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerRegistryName: containerRegistryName
    containerCpuCoreCount: '1'
    containerMemory: '2Gi'
    containerMinReplicas: 1
    containerMaxReplicas: 10
    external: true
    env: [
      {
        name: 'RUNNING_IN_PRODUCTION'
        value: 'true'
      }
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: applicationInsights.properties.ConnectionString
      }
      {
        name: 'AZURE_CLIENT_ID'
        value: identityClientId
      }
      {
        name: 'BACKEND_1_URL'
        value: backend_1_url
        // Continue with the rest of the environment variables
      }
      {
        name: 'BACKEND_1_PRIORITY'
        value: string(backend_1_priority)
      }
      {
        name: 'BACKEND_2_URL'
        value: backend_2_url
      }
      {
        name: 'BACKEND_2_PRIORITY'
        value: string(backend_2_priority)
      }
      {
        name: 'BACKEND_3_URL'
        value: backend_3_url
      }
      {
        name: 'BACKEND_3_PRIORITY'
        value: string(backend_3_priority)
      }
    ]
    imageName: 'andredewes/aoai-smart-loadbalancing:v1'
    targetPort: 8080
  }
  dependsOn: [
    containerApps
  ]
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

output SERVICE_WEB_NAME string = app.outputs.name
output SERVICE_WEB_URI string = app.outputs.uri
output SERVICE_WEB_IMAGE_NAME string = app.outputs.imageName

output uri string = app.outputs.uri
