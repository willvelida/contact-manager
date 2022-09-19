@description('The location to deploy our resources to. Default is the location of the resource group')
param location string

@description('The name of the Log Analytics workspace')
param logAnalyticsWorkspaceName string

@description('The key vault used to store secrets')
param keyVaultName string

var sharedKeySecretName = 'log-analytics-shared-key'

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource law 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource sharedKeySecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: sharedKeySecretName
  parent: keyVault
  properties: {
    value: law.listKeys().primarySharedKey
  }
}

output logAnalyticsId string = law.id
output customerId string = law.properties.customerId
