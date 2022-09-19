@description('The location to deploy our container registry to')
param location string

@description('The name of the Container Registry')
param containerRegistryName string

@description('The key vault used to store the ACR secrets')
param keyVaultName string

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' = {
  name: containerRegistryName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
  identity: {
    type: 'SystemAssigned'
  } 
}

resource acrPasswordSecret1 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'acrPassword1'
  parent: keyVault
  properties: {
    value: containerRegistry.listCredentials().passwords[0].value
  }
}

resource acrPasswordSecret2 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'acrPassword2'
  parent: keyVault
  properties: {
    value: containerRegistry.listCredentials().passwords[1].value
  }
}

resource acrUsername 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'acrUsername'
  parent: keyVault
  properties: {
    value: containerRegistry.listCredentials().username
  }
}

output loginServer string = containerRegistry.properties.loginServer
output containerRegistryPrincipalId string = containerRegistry.identity.principalId
