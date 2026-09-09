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

DEPLOYMENT_NAME="custtable-$(basename "$(dirname "$PARAM_FILE")")-$(date +%Y%m%d%H%M%S)"

az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$DEPLOYMENT_NAME" \
  --template-file "$PARAM_FILE" \
  --query "properties.outputs"
