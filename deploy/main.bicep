@description('The location to deploy our resources to. Default is the location of the resource group')
param location string = resourceGroup().location

@description('Random name for our application')
param applicationName string = uniqueString(resourceGroup().id)

@description('The name of our Container App Environment')
param containerAppEnvName string = 'env${applicationName}'

@description('The name of the Log Analytics workspace')
param logAnalyticsWorkspace string = 'law${applicationName}'

@description('The name of the key vault that will be deployed')
param keyVaultName string = '${applicationName}kv'

@description('The name of the Azure Container Registry that will be deployed')
param containerRegistryName string = '${applicationName}acr'

@description('The name of the App Insights workspace')
param appInsightsWorkspace string = 'appins${applicationName}'

var apiAppName = 'contact-api'
var webAppName = 'contact-web'

var envVariables = [
  {
    name: 'ASPNETCORE_ENVIRONMENT'
    value: 'Development'
  }
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: appInsights.properties.ConnectionString
  }
  {
    name: 'APPLICATIONINSIGHTS_INSTRUMENTATIONKEY'
    value: appInsights.properties.InstrumentationKey
  }
]

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enableSoftDelete: false
    accessPolicies: [
    ]
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsWorkspace
  location: location 
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: law.outputs.logAnalyticsId
  }
}

module law 'modules/logAnalytics.bicep' = {
  name: 'law'
  params: {
    logAnalyticsWorkspaceName: logAnalyticsWorkspace
    location: location
    keyVaultName: keyVault.name
  }
}

module containerRegistry 'modules/containerRegistry.bicep' = {
  name: 'acr'
  params: {
    containerRegistryName: containerRegistryName
    location: location
    keyVaultName: keyVault.name
  }
}

module contactApi 'modules/containerApp.bicep' = {
  name: 'contact-api'
  params: {
    acrPasswordSecret: keyVault.getSecret('acrPassword1')
    acrServerName: containerRegistry.outputs.loginServer
    acrUsername: keyVault.getSecret('acrUsername')
    containerAppEnvId: containerAppEnvironment.outputs.environmentId
    containerAppName: apiAppName
    containerImage: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
    isExternal: false
    location: location
    envVariables: envVariables
  }
}

module contactWeb 'modules/containerApp.bicep' = {
  name: 'contact-web'
  params: {
    acrPasswordSecret: keyVault.getSecret('acrPassword1')
    acrServerName: containerRegistry.outputs.loginServer
    acrUsername: keyVault.getSecret('acrUsername')
    containerAppEnvId: containerAppEnvironment.outputs.environmentId
    containerAppName: webAppName
    containerImage: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
    isExternal: true
    location: location
    envVariables: envVariables
  }
}

module containerAppEnvironment 'modules/containerAppEnvironment.bicep' = {
  name: 'env'
  params: {
    containerAppEnvName: containerAppEnvName 
    lawCustomerId: law.outputs.customerId
    lawCustomerKey: keyVault.getSecret('log-analytics-shared-key')
    location: location
  }
}
