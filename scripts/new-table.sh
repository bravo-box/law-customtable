#!/usr/bin/env bash
set -euo pipefail

# Scaffolds a new tables/<TableName_CL>/ folder with a starter Bicep parameters
# file and sample ingestion payload.
#
# Usage: ./scripts/new-table.sh MyApp_CL

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <TableName_CL>" >&2
  exit 1
fi

TABLE_NAME="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TARGET_DIR="$REPO_ROOT/tables/$TABLE_NAME"

if [[ "$TABLE_NAME" != *_CL ]]; then
  echo "Table name must end with _CL (got: $TABLE_NAME)" >&2
  exit 1
fi

if [[ -d "$TARGET_DIR" ]]; then
  echo "Table folder already exists: $TARGET_DIR" >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"

cat > "$TARGET_DIR/main.bicepparam" <<EOF
using '../../bicep/main.bicep'

param workspaceName = 'CHANGE_ME-law'
param location = 'eastus'
param tableName = '$TABLE_NAME'
param columns = [
  { name: 'TimeGenerated', type: 'datetime' }
  { name: 'Message', type: 'string' }
]
param tablePlan = 'Analytics'
param retentionInDays = -1
param totalRetentionInDays = -1
param ingestPrincipalId = ''
param tags = {}
EOF

cat > "$TARGET_DIR/sample-payload.json" <<EOF
[
  {
    "TimeGenerated": "2026-01-01T00:00:00Z",
    "Message": "sample message"
  }
]
EOF

echo "Created $TARGET_DIR"
echo "Next steps:"
echo "  1. Edit $TARGET_DIR/main.bicepparam (workspaceName, columns, retention)"
echo "  2. Edit $TARGET_DIR/sample-payload.json to match your columns"
echo "  3. ./scripts/deploy-table.sh <resource-group> tables/$TABLE_NAME/main.bicepparam"
