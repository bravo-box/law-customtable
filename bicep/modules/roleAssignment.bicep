@description('Name of an existing Data Collection Rule to grant ingestion permissions on.')
param dcrName string

@description('Object ID of the principal (managed identity, service principal, or user) that will send data.')
param principalId string

@description('Type of the principal being granted access.')
param principalType 'ServicePrincipal' | 'User' | 'Group' = 'ServicePrincipal'

// Built-in "Monitoring Metrics Publisher" role - required to call the Logs Ingestion API against a DCR.
var monitoringMetricsPublisherRoleId = '3913510d-42f4-4e42-8a64-420c390055eb'

resource dcr 'Microsoft.Insights/dataCollectionRules@2023-03-11' existing = {
  name: dcrName
}

resource ingestRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(dcr.id, principalId, monitoringMetricsPublisherRoleId)
  scope: dcr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', monitoringMetricsPublisherRoleId)
    principalId: principalId
    principalType: principalType
  }
}
