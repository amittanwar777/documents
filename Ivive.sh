#!/bin/bash

# Output file
OUTPUT_FILE="openshift_resources.txt"

# Clear the output file
> $OUTPUT_FILE

# Get all namespaces
NAMESPACES=$(oc get namespaces -o jsonpath='{.items[*].metadata.name}')

# Loop through each namespace
for NS in $NAMESPACES; do
    echo "Namespace: $NS" >> $OUTPUT_FILE
    echo "=============================" >> $OUTPUT_FILE

    # Get Pods
    echo "Pods:" >> $OUTPUT_FILE
    oc get pods -n $NS >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE

    # Get Deployments
    echo "Deployments:" >> $OUTPUT_FILE
    oc get deployments -n $NS >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE

    # Get Routes
    echo "Routes:" >> $OUTPUT_FILE
    oc get routes -n $NS >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE

    echo "=============================" >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE
done

echo "Output written to $OUTPUT_FILE"