#!/bin/bash

JSON_FILE="mapping.json"
OUTPUT_FILE="output.json"

# Initialize an empty JSON object
echo "{" > "$OUTPUT_FILE"

# Iterate over environments
jq -r '.environments | keys[]' "$JSON_FILE" | while read -r env; do
  echo "  \"$env\": {" >> "$OUTPUT_FILE"
  echo "    \"namespaces\": [" >> "$OUTPUT_FILE"

  # Get all namespace keys dynamically
  jq -r ".environments[\"$env\"] | keys[]" "$JSON_FILE" | while read -r ns_key; do
    ns_value=$(jq -r ".environments[\"$env\"][\"$ns_key\"]" "$JSON_FILE")

    echo "      {" >> "$OUTPUT_FILE"
    echo "        \"namespace\": \"$ns_value\"," >> "$OUTPUT_FILE"

    # Capture pod details in JSON format
    PODS=$(oc get pods -n "$ns_value" -o json | jq -c '.items | map({name: .metadata.name, status: .status.phase})')
    
    echo "        \"pods\": $PODS" >> "$OUTPUT_FILE"
    echo "      }," >> "$OUTPUT_FILE"
  done

  # Remove trailing comma and close the JSON
  sed -i '$ s/,$//' "$OUTPUT_FILE"
  echo "    ]" >> "$OUTPUT_FILE"
  echo "  }," >> "$OUTPUT_FILE"
done

# Remove trailing comma and close JSON
sed -i '$ s/,$//' "$OUTPUT_FILE"
echo "}" >> "$OUTPUT_FILE"