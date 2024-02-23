targetScope = 'subscription'

@description('Specifies the location for all resources.')
param location string

@description('SKU name for OpenAI.')
param openAiSkuName string = 'S0'

@description('Version of the Chat GPT model.')
param chatGptModelVersion string = '0613'

@description('Name of the Chat GPT deployment.')
param chatGptDeploymentName string = 'chat'

@description('Name of the Chat GPT model.')
param embeddingGptModelName string = 'text-embedding-ada-002'

@description('Version of the Chat GPT model.')
param embeddingGptModelVersion string = '2'

@description('Name of the Chat GPT deployment.')
param embeddingGptDeploymentName string = 'embedding'

@description('Name of the Chat GPT model.')
param chatGptModelName string = 'gpt-35-turbo'

// You can add more OpenAI instances by adding more objects to the openAiInstances object
// Then update the apim policy xml to include the new instances
@description('Object containing OpenAI instances. You can add more instances by adding more objects to this parameter.')
param openAiInstances object = {
  openAi1: {
    name: 'openai1'
    location: 'eastus'
  }
  openAi2: {
    name: 'openai2'
    location: 'northcentralus'
  }
  openAi3: {
    name: 'openai3'
    location: 'eastus2'
  }
}

@minLength(1)
@maxLength(64)
@description('Name which is used to generate a short unique hash for each resource')
param name string

// Load abbreviations from JSON file
var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, name, location))
var prefix = '${name}-${resourceToken}'
var tags = { 'azd-env-name': name }



resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${name}-rg'
  location: location
  tags: tags
}

// Monitor application with Azure Monitor
module monitoring 'core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    applicationInsightsDashboardName: '${prefix}-appinsights-dashboard'
    applicationInsightsName: '${prefix}-appinsights'
    logAnalyticsName: '${take(prefix, 50)}-loganalytics' // Max 63 chars
  }
}

module managedIdentity 'core/security/managed-identity.bicep' = {
  name: 'managed-identity'
  scope: resourceGroup
  params: {
    name: '${abbrs.managedIdentityUserAssignedIdentities}${resourceToken}'
    location: location
    tags: tags
  }
}

// Web frontend
module web 'web.bicep' = {
  name: 'web'
  scope: resourceGroup
  params: {
    name: replace('${take(prefix, 19)}-ca', '--', '-')
    location: location
    tags: tags
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    logAnalyticsWorkspaceName: monitoring.outputs.logAnalyticsWorkspaceName
    identityName: managedIdentity.outputs.managedIdentityName
    identityClientId: managedIdentity.outputs.managedIdentityClientId
    containerAppsEnvironmentName: '${prefix}-containerapps-env'
    containerRegistryName: '${replace(prefix, '-', '')}registry'
    backend_1_url: openAis[0].outputs.openAiEndpointUri
    backend_1_priority: 1
    backend_2_url: openAis[1].outputs.openAiEndpointUri
    backend_2_priority: 2
    backend_3_url: openAis[2].outputs.openAiEndpointUri
    backend_3_priority: 3
  }
}

module openAis 'core/ai/cognitiveservices.bicep' = [for (config, i) in items(openAiInstances): {
  name: '${config.value.name}-${resourceToken}'
  scope: resourceGroup
  params: {
    name: '${config.value.name}-${resourceToken}'
    location: config.value.location
    tags: tags
    managedIdentityName: managedIdentity.outputs.managedIdentityName
    sku: {
      name: openAiSkuName
    }
    deploymentCapacity: 1
    deployments: [
      {
        name: chatGptDeploymentName
        model: {
          format: 'OpenAI'
          name: chatGptModelName
          version: chatGptModelVersion
        }
        scaleSettings: {
          scaleType: 'Standard'
        }
      }
      {
        name: embeddingGptDeploymentName
        model: {
          format: 'OpenAI'
          name: embeddingGptModelName
          version: embeddingGptModelVersion
        }
        sku: {
          name: 'Standard'
          capacity: 1
        }
      }
    ]
  }
}]

output CONTAINER_APP_URL string =web.outputs.uri
