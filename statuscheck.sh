#!/bin/bash

JSON_FILE="mapping.json"
OUTPUT_FILE="output.json"

# Define datacenters
DATACENTERS=("sl" "gl")

# Initialize JSON output
echo "{" > "$OUTPUT_FILE"

# Iterate over datacenters
for dc in "${DATACENTERS[@]}"; do
  echo "Logging into datacenter: $dc"
  oc login --server="https://$dc.openshift-cluster.com" --token="YOUR_TOKEN"

  # Iterate over environments
  jq -r '.environments | keys[]' "$JSON_FILE" | while read -r env; do
    echo "  \"$env-$dc\": {" >> "$OUTPUT_FILE"
    echo "    \"namespaces\": [" >> "$OUTPUT_FILE"

    # Get all namespace keys dynamically
    jq -r ".environments[\"$env\"] | keys[]" "$JSON_FILE" | while read -r ns_key; do
      ns_value=$(jq -r ".environments[\"$env\"][\"$ns_key\"]" "$JSON_FILE")

      echo "      {" >> "$OUTPUT_FILE"
      echo "        \"namespace_key\": \"$ns_key\"," >> "$OUTPUT_FILE"
      echo "        \"namespace\": \"$ns_value\"," >> "$OUTPUT_FILE"

      # Get only running pods
      PODS=$(oc get pods -n "$ns_value" --field-selector=status.phase=Running -o json | jq -c '.items | map({name: .metadata.name, status: .status.phase})')

      echo "        \"pods\": $PODS" >> "$OUTPUT_FILE"
      echo "      }," >> "$OUTPUT_FILE"
    done

    # Remove trailing comma and close the JSON
    sed -i '$ s/,$//' "$OUTPUT_FILE"
    echo "    ]" >> "$OUTPUT_FILE"
    echo "  }," >> "$OUTPUT_FILE"
  done
done

# Remove trailing comma and close JSON
sed -i '$ s/,$//' "$OUTPUT_FILE"
echo "}" >> "$OUTPUT_FILE"