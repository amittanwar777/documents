#!/bin/bash

# Path to your deployment file
DEPLOYMENT_FILE="deployment.yaml"

# Apply the deployment file and capture the output
OUTPUT=$(oc apply -f "$DEPLOYMENT_FILE")

# Check if the output contains "unchanged"
if echo "$OUTPUT" | grep -q "unchanged"; then
  echo "No changes detected, triggering a rollout..."
  oc rollout restart deployment/nginx
else
  echo "Changes applied or configured, no rollout needed."
fi