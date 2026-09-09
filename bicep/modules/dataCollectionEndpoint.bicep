@description('Name of the Data Collection Endpoint.')
param name string

@description('Azure region for the endpoint.')
param location string

@description('Tags applied to the resource.')
param tags object = {}

@description('Whether the logs ingestion endpoint accepts traffic from the public internet.')
param publicNetworkAccess 'Enabled' | 'Disabled' = 'Enabled'

resource dce 'Microsoft.Insights/dataCollectionEndpoints@2023-03-11' = {
  name: name
  location: location
  tags: tags
  properties: {
    networkAcls: {
      publicNetworkAccess: publicNetworkAccess
    }
  }
}

output id string = dce.id
output name string = dce.name
output logsIngestionEndpoint string = dce.properties.logsIngestion.endpoint
