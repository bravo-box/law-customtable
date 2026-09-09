#!/usr/bin/env bash
set -euo pipefail

# Sends a sample payload to a table's Data Collection Rule via the Logs
# Ingestion API, using the signed-in az CLI identity for auth. That identity
# must hold "Monitoring Metrics Publisher" on the DCR (see modules/roleAssignment.bicep
# or the ingestPrincipalId parameter in main.bicep).
#
# Usage: ./scripts/ingest-sample.sh <dce-logs-ingestion-endpoint> <dcr-immutable-id> <stream-name> <payload-file>
# Example:
#   ./scripts/ingest-sample.sh https://dce-example-xxxx.eastus-1.ingest.monitor.azure.com \
#     dcr-immutable-id \
#     Custom-Example_CL \
#     tables/Example_CL/sample-payload.json

if [[ $# -ne 4 ]]; then
  echo "Usage: $0 <dce-logs-ingestion-endpoint> <dcr-immutable-id> <stream-name> <payload-file>" >&2
  exit 1
fi

DCE_ENDPOINT="$1"
DCR_IMMUTABLE_ID="$2"
STREAM_NAME="$3"
PAYLOAD_FILE="$4"

if [[ ! -f "$PAYLOAD_FILE" ]]; then
  echo "Payload file not found: $PAYLOAD_FILE" >&2
  exit 1
fi

ACCESS_TOKEN="$(az account get-access-token --resource https://monitor.azure.com --query accessToken -o tsv)"

curl -sS -X POST \
  "${DCE_ENDPOINT}/dataCollectionRules/${DCR_IMMUTABLE_ID}/streams/${STREAM_NAME}?api-version=2023-01-01" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  --data @"$PAYLOAD_FILE" \
  -w "\nHTTP status: %{http_code}\n"
