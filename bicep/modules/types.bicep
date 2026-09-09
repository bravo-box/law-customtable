// Shared user-defined types for custom table / DCE / DCR modules.

@export()
@description('A single column in a custom log table and its matching ingestion stream.')
type tableColumn = {
  @description('Column name. Use TimeGenerated:datetime for the required timestamp column.')
  name: string
  @description('Column data type.')
  type: 'string' | 'int' | 'long' | 'real' | 'boolean' | 'datetime' | 'dynamic' | 'guid'
}
