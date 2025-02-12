#!/bin/bash

JSON_FILE="mapping.json"
OUTPUT_FILE="output.json"

# Initialize an empty JSON object
echo "{" > "$OUTPUT_FILE"

# Iterate over environments
jq -r '.environments | keys[]' "$JSON_FILE" | while read -r env; do
  echo "  \"$env\": {" >> "$OUTPUT_FILE"

  # Get the namespace values dynamically
  ca=$(jq -r ".environments[\"$env\"].ca" "$JSON_FILE")
  cs=$(jq -r ".environments[\"$env\"].cs" "$JSON_FILE")

  echo "    \"namespaces\": [" >> "$OUTPUT_FILE"

  for ns in "$ca" "$cs"; do
    echo "      {" >> "$OUTPUT_FILE"
    echo "        \"namespace\": \"$ns\"," >> "$OUTPUT_FILE"

    # Capture pod details in JSON format
    PODS=$(oc get pods -n "$ns" -o json | jq -c '.items | map({name: .metadata.name, status: .status.phase})')
    
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