@description('The location to deploy our resources to. Default is the location of the resource group')
param location string

@description('The name of our Container App Environment')
param containerAppEnvName string

@description('The Log Analytics Customer Id for this container apps environment')
param lawCustomerId string

@description('The shared key for Log Analytics')
@secure()
param lawCustomerKey string

resource env 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: containerAppEnvName
  location: location 
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: lawCustomerId
        sharedKey: lawCustomerKey
      }
    }
  }
}

output environmentId string = env.id
