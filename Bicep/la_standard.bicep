param location string  = resourceGroup().location
param environmentName string 
param projectName string 
param logicAppName string
param appServicePlanName string

@minLength(3)
@maxLength(24)
param storageName string

param kind string = 'StorageV2'
param skuName string = 'Standard_LRS'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  sku: {
    name: skuName
  }
  kind: kind
  name: storageName
  location: location
  tags: {
    'Environment': environmentName
    'Project': projectName
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  tags: {
    'Environment': environmentName
    'Project': projectName
  }
  sku: {
    name: 'WS1'
    tier: 'WorkflowStandard'
  }
  kind: 'Windows'
}

resource logicApp 'Microsoft.Web/sites@2022-03-01' = {
  name: logicAppName
  location: location
  kind: 'workflowapp,functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  tags: {
    'Environment': environmentName
    'Project': projectName
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      netFrameworkVersion: 'v4.6'
      appSettings: [
        {
          'name': 'APP_KIND'
          'value': 'workflowApp'
        }
        {
          'name': 'AzureFunctionsJobHost__extensionBundle__id'
          'value': 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
        }
        {
          'name': 'AzureFunctionsJobHost__extensionBundle__version'
          'value': '[1.*, 2.0.0)'
        }
        {
          'name': 'AzureWebJobsStorage'
          'value': 'DefaultEndpointsProtocol=https;AccountName=${storageName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          'name': 'FUNCTIONS_EXTENSION_VERSION'
          'value': '~4'
        }
        {
          'name': 'FUNCTIONS_WORKER_RUNTIME'
          'value': 'node'
        }
        {
          'name': 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          'value': 'DefaultEndpointsProtocol=https;AccountName=${storageName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          'name': 'WEBSITE_CONTENTSHARE'
          'value': logicAppName
        }
        {
          'name': 'WEBSITE_NODE_DEFAULT_VERSION'
          'value': '~14'
        } 
      ]      
    }
    clientAffinityEnabled: false
  }
}
