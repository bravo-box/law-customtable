import { tableColumn } from 'types.bicep'

@description('Name of the existing Log Analytics workspace to add the table to.')
param workspaceName string

@description('Name of the custom table. Must end with _CL.')
param tableName string

@description('Column definitions for the table, including TimeGenerated.')
param columns tableColumn[]

@description('Table plan controlling cost/retention behavior.')
param plan 'Basic' | 'Analytics' = 'Analytics'

@description('Interactive retention in days, between 4 and 730. -1 uses the workspace default.')
param retentionInDays int = -1

@description('Total retention in days including archive, between 4 and 4383. -1 uses the workspace default.')
param totalRetentionInDays int = -1

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

resource table 'Microsoft.OperationalInsights/workspaces/tables@2022-10-01' = {
  parent: workspace
  name: tableName
  properties: {
    plan: plan
    retentionInDays: retentionInDays
    totalRetentionInDays: totalRetentionInDays
    schema: {
      name: tableName
      columns: columns
    }
  }
}

output id string = table.id
output name string = table.name
