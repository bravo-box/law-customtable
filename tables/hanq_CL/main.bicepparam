using '../../bicep/main.bicep'

param workspaceName = 'bravo-box-law'
param location = 'usgovvirginia'
param tableName = 'hanq_CL'
param columns = [
  { name: 'TimeGenerated', type: 'datetime' }
  { name: 'Message', type: 'string' }
]
param tablePlan = 'Analytics'
param retentionInDays = -1
param totalRetentionInDays = -1
param ingestPrincipalId = ''
param tags = {}
