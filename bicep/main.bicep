import { tableColumn } from 'modules/types.bicep'

@description('Name of the existing Log Analytics workspace to attach the custom table to.')
param workspaceName string

@description('Azure region for the Data Collection Endpoint and Data Collection Rule.')
param location string = resourceGroup().location

@description('Name of the custom table to create. Must end with _CL.')
@minLength(4)
param tableName string

@description('Column definitions shared by the table schema and the ingestion stream. Must include TimeGenerated:datetime.')
param columns tableColumn[]

@description('Table plan controlling cost/retention behavior.')
param tablePlan 'Basic' | 'Analytics' = 'Analytics'

@description('Interactive retention in days. -1 uses the workspace default.')
param retentionInDays int = -1

@description('Total retention in days including archive. -1 uses the workspace default.')
param totalRetentionInDays int = -1

@description('Name of the Data Collection Endpoint to create.')
param dceName string = 'dce-${toLower(replace(tableName, '_CL', ''))}'

@description('Name of the Data Collection Rule to create.')
param dcrName string = 'dcr-${toLower(replace(tableName, '_CL', ''))}'

@description('Object ID of the principal that will send data via the Logs Ingestion API. Leave empty to skip role assignment.')
param ingestPrincipalId string = ''

@description('Type of ingestPrincipalId.')
param ingestPrincipalType 'ServicePrincipal' | 'User' | 'Group' = 'ServicePrincipal'

@description('Tags applied to created resources.')
param tags object = {}

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

module table 'modules/customTable.bicep' = {
  params: {
    workspaceName: workspaceName
    tableName: tableName
    columns: columns
    plan: tablePlan
    retentionInDays: retentionInDays
    totalRetentionInDays: totalRetentionInDays
  }
}

module dce 'modules/dataCollectionEndpoint.bicep' = {
  params: {
    name: dceName
    location: location
    tags: tags
  }
}

module dcr 'modules/dataCollectionRule.bicep' = {
  params: {
    name: dcrName
    location: location
    tags: tags
    dataCollectionEndpointId: dce.outputs.id
    workspaceResourceId: workspace.id
    tableName: tableName
    columns: columns
  }
  dependsOn: [
    table
  ]
}

module ingestRoleAssignment 'modules/roleAssignment.bicep' = if (!empty(ingestPrincipalId)) {
  params: {
    dcrName: dcrName
    principalId: ingestPrincipalId
    principalType: ingestPrincipalType
  }
  dependsOn: [
    dcr
  ]
}

@description('URL clients POST log data to, appended with /dataCollectionRules/{dcrImmutableId}/streams/{streamName}?api-version=2023-01-01.')
output dceLogsIngestionEndpoint string = dce.outputs.logsIngestionEndpoint

@description('Immutable ID of the Data Collection Rule, required in the ingestion URL.')
output dcrImmutableId string = dcr.outputs.immutableId

@description('Stream name declared on the DCR, required in the ingestion URL.')
output streamName string = dcr.outputs.streamName

@description('Name of the deployed custom table.')
output tableName string = table.outputs.name
