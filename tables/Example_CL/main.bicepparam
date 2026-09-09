using '../../bicep/main.bicep'

param workspaceName = 'CHANGE_ME-law'
param location = 'eastus'
param tableName = 'Example_CL'
param columns = [
  { name: 'TimeGenerated', type: 'datetime' }
  { name: 'Message', type: 'string' }
  { name: 'Severity', type: 'string' }
  { name: 'HostName', type: 'string' }
]
param tablePlan = 'Analytics'
param retentionInDays = -1
param totalRetentionInDays = -1
param ingestPrincipalId = ''
param tags = {
  environment: 'dev'
}
