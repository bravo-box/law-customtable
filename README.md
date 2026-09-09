# law-customtable

Repeatable Bicep + scripts to create a Log Analytics **custom table**, a
**Data Collection Endpoint (DCE)**, and a **Data Collection Rule (DCR)** for
ingesting data via the [Logs Ingestion API](https://learn.microsoft.com/azure/azure-monitor/logs/logs-ingestion-api-overview).

Each custom table gets its own folder under `tables/` with a `.bicepparam`
file defining the schema, so adding a new table is just: scaffold, edit
columns, deploy.

## Layout

```
bicep/
  main.bicep                     # orchestrates table + DCE + DCR (+ optional role assignment)
  modules/
    types.bicep                  # shared tableColumn type
    customTable.bicep            # Microsoft.OperationalInsights/workspaces/tables
    dataCollectionEndpoint.bicep # Microsoft.Insights/dataCollectionEndpoints
    dataCollectionRule.bicep     # Microsoft.Insights/dataCollectionRules
    roleAssignment.bicep         # grants Monitoring Metrics Publisher on the DCR
tables/
  Example_CL/
    main.bicepparam              # per-table parameters (workspace, schema, retention)
    sample-payload.json          # example row(s) matching the table schema
scripts/
  new-table.sh                   # scaffolds tables/<TableName_CL>/
  deploy-table.sh                # az deployment group create wrapper
  ingest-sample.sh               # posts sample-payload.json to the DCE/DCR
```

## Prerequisites

- Azure CLI, logged in (`az login`) with Bicep support (`az bicep upgrade`).
- An existing Log Analytics workspace in the target resource group.
- Permission to create Insights/OperationalInsights resources and (optionally)
  role assignments in that resource group.

## Add a new table

```bash
./scripts/new-table.sh MyApp_CL
```

Edit the generated files:

- `tables/MyApp_CL/main.bicepparam` — set `workspaceName`, `location`, and
  `columns`. **Always include `{ name: 'TimeGenerated', type: 'datetime' }`**
  — it's required on every custom log table/stream.
- `tables/MyApp_CL/sample-payload.json` — one or more sample rows matching
  `columns`, used only for the test ingest below.

Deploy:

```bash
./scripts/deploy-table.sh <resource-group> tables/MyApp_CL/main.bicepparam
```

This prints the deployment outputs:

- `dceLogsIngestionEndpoint` — base URL for posting logs
- `dcrImmutableId` — DCR identifier used in the ingestion URL
- `streamName` — stream name used in the ingestion URL (`Custom-MyApp_CL`)

## Granting ingestion access

Whatever identity sends data (an app's managed identity, a service principal,
or your own user for testing) needs the built-in **Monitoring Metrics
Publisher** role on the DCR. Either:

- Set `ingestPrincipalId` (and `ingestPrincipalType` if not a service
  principal) in the table's `main.bicepparam` before deploying, or
- Assign it manually afterwards:

  ```bash
  az role assignment create \
    --assignee <principal-id> \
    --role "Monitoring Metrics Publisher" \
    --scope <dcr-resource-id>
  ```

## Test ingestion

```bash
./scripts/ingest-sample.sh \
  <dceLogsIngestionEndpoint> \
  <dcrImmutableId> \
  <streamName> \
  tables/MyApp_CL/sample-payload.json
```

Uses your current `az login` session for auth, so that identity must have the
role above. Query the table in Log Analytics (allow a few minutes for
ingestion) to confirm rows arrived.

## Notes

- Table names must end with `_CL`.
- The DCR's stream is named `Custom-<TableName>` and is used as its own
  output stream (no transform), so the table schema and stream
  `columns` must match exactly.
- Deleting a custom table only soft-deletes it; the name stays reserved for a
  purge-recovery window before it can be reused.
