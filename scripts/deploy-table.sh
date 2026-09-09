#!/usr/bin/env bash
set -euo pipefail

# Deploys a custom table + Data Collection Endpoint + Data Collection Rule from
# a per-table Bicep parameters file, and prints the deployment outputs needed
# for ingestion (DCE endpoint, DCR immutable ID, stream name).
#
# Usage: ./scripts/deploy-table.sh <resource-group> <path-to-bicepparam>

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <resource-group> <path-to-bicepparam>" >&2
  exit 1
fi

RESOURCE_GROUP="$1"
PARAM_FILE="$2"

if [[ ! -f "$PARAM_FILE" ]]; then
  echo "Parameter file not found: $PARAM_FILE" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
DEPLOYMENT_NAME="custtable-$(basename "$(dirname "$PARAM_FILE")")-$(date +%Y%m%d%H%M%S)"

# Pre-compile to ARM JSON: `az deployment group create` calls with a raw .bicepparam
# file can hit "Failed to parse ... valid JSON format" for templates using compile-time
# imports (see bicep/modules/types.bicep), even though `az bicep build` handles them fine.
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

az bicep build --file "$REPO_ROOT/bicep/main.bicep" --outfile "$WORK_DIR/main.json"
az bicep build-params --file "$PARAM_FILE" --outfile "$WORK_DIR/main.parameters.json"

az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$DEPLOYMENT_NAME" \
  --template-file "$WORK_DIR/main.json" \
  --parameters "$WORK_DIR/main.parameters.json" \
  --query "properties.outputs"
