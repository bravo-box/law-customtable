import { tableColumn } from 'types.bicep'

@description('Name of the Data Collection Rule.')
param name string

@description('Azure region for the rule.')
param location string

@description('Tags applied to the resource.')
param tags object = {}

@description('Resource ID of the Data Collection Endpoint used for direct ingestion.')
param dataCollectionEndpointId string

@description('Resource ID of the destination Log Analytics workspace.')
param workspaceResourceId string

@description('Name of the custom table. Must end with _CL and match the deployed table.')
param tableName string

@description('Column definitions for the ingestion stream, including TimeGenerated. Must match the table schema.')
param columns tableColumn[]

// Custom log streams must be prefixed with "Custom-"; using it as the output stream too keeps a 1:1 mapping to the table.
var streamName = 'Custom-${tableName}'
var destinationName = 'logAnalyticsDestination'

resource dcr 'Microsoft.Insights/dataCollectionRules@2023-03-11' = {
  name: name
  location: location
  tags: tags
  properties: {
    dataCollectionEndpointId: dataCollectionEndpointId
    streamDeclarations: {
      '${streamName}': {
        columns: columns
      }
    }
    destinations: {
      logAnalytics: [
        {
          name: destinationName
          workspaceResourceId: workspaceResourceId
        }
      ]
    }
    dataFlows: [
      {
        streams: [streamName]
        destinations: [destinationName]
        outputStream: streamName
        transformKql: 'source'
      }
    ]
  }
}

output id string = dcr.id
output name string = dcr.name
output immutableId string = dcr.properties.immutableId
output streamName string = streamName
