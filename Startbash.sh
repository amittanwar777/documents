#!/bin/bash

# File to store previous replica counts
STATE_FILE="replica_state.json"

# Check if we're restoring or scaling down
RESTORE_MODE=false
if [[ -f "$STATE_FILE" ]]; then
    echo "Replica state file found. Will attempt to restore deployments..."
    RESTORE_MODE=true
else
    echo "No state file found. Will scale down and record replicas..."
    echo "{}" > "$STATE_FILE"
fi

# Loop through all OpenShift projects
for ns in $(oc get projects -o jsonpath='{.items[*].metadata.name}'); do
    echo "Processing namespace: $ns"

    # Process DeploymentConfigs
    for dc in $(oc get dc -n "$ns" -o jsonpath='{.items[*].metadata.name}'); do
        replicas=$(oc get dc "$dc" -n "$ns" -o jsonpath='{.spec.replicas}')
        if [[ "$RESTORE_MODE" == false && "$replicas" -gt 0 ]]; then
            echo "Scaling down dc/$dc in $ns from $replicas to 0"
            jq --arg ns "$ns" --arg name "$dc" --argjson replicas "$replicas" \
                '.[$ns + "/dc/" + $name] = $replicas' "$STATE_FILE" > tmp.$$.json && mv tmp.$$.json "$STATE_FILE"
            oc scale dc "$dc" -n "$ns" --replicas=0
        elif [[ "$RESTORE_MODE" == true ]]; then
            saved_replicas=$(jq -r --arg key "$ns/dc/$dc" '.[$key] // empty' "$STATE_FILE")
            if [[ -n "$saved_replicas" ]]; then
                echo "Restoring dc/$dc in $ns to $saved_replicas replicas"
                oc scale dc "$dc" -n "$ns" --replicas="$saved_replicas"
            fi
        fi
    done

    # Process Deployments
    for deploy in $(oc get deploy -n "$ns" -o jsonpath='{.items[*].metadata.name}'); do
        replicas=$(oc get deploy "$deploy" -n "$ns" -o jsonpath='{.spec.replicas}')
        if [[ "$RESTORE_MODE" == false && "$replicas" -gt 0 ]]; then
            echo "Scaling down deployment/$deploy in $ns from $replicas to 0"
            jq --arg ns "$ns" --arg name "$deploy" --argjson replicas "$replicas" \
                '.[$ns + "/deploy/" + $name] = $replicas' "$STATE_FILE" > tmp.$$.json && mv tmp.$$.json "$STATE_FILE"
            oc scale deploy "$deploy" -n "$ns" --replicas=0
        elif [[ "$RESTORE_MODE" == true ]]; then
            saved_replicas=$(jq -r --arg key "$ns/deploy/$deploy" '.[$key] // empty' "$STATE_FILE")
            if [[ -n "$saved_replicas" ]]; then
                echo "Restoring deployment/$deploy in $ns to $saved_replicas replicas"
                oc scale deploy "$deploy" -n "$ns" --replicas="$saved_replicas"
            fi
        fi
    done
done

# Cleanup the state file after restoring
if [[ "$RESTORE_MODE" == true ]]; then
    echo "Restoration complete. Removing state file."
    rm -f "$STATE_FILE"
fi