#!/bin/bash
set -euo pipefail

# Temporary file for restore mode (only used if REPLICA_STATE_JSON is passed)
STATE_FILE="/tmp/replica_state.json"

# Detect restore mode via Jenkins parameter
RESTORE_MODE=false
if [[ -n "${REPLICA_STATE_JSON:-}" ]]; then
    echo "Replica state JSON provided. Entering restore mode..."
    echo "$REPLICA_STATE_JSON" > "$STATE_FILE"
    RESTORE_MODE=true
else
    echo "No replica state JSON provided. Scaling down and collecting state..."
    echo "{}" > "$STATE_FILE"
fi

# Loop through all OpenShift projects
for ns in $(oc get projects -o jsonpath='{.items[*].metadata.name}'); do
    echo "Processing namespace: $ns"

    # Handle DeploymentConfigs
    for dc in $(oc get dc -n "$ns" -o jsonpath='{.items[*].metadata.name}'); do
        if [[ "$RESTORE_MODE" == false ]]; then
            replicas=$(oc get dc "$dc" -n "$ns" -o jsonpath='{.spec.replicas}')
            if [[ "$replicas" -gt 0 ]]; then
                echo "Scaling down dc/$dc in $ns from $replicas to 0"
                jq --arg ns "$ns" --arg name "$dc" --argjson replicas "$replicas" \
                   '.[$ns + "/dc/" + $name] = $replicas' "$STATE_FILE" > tmp.$$.json && mv tmp.$$.json "$STATE_FILE"
                oc scale dc "$dc" -n "$ns" --replicas=0
            fi
        else
            saved_replicas=$(jq -r --arg key "$ns/dc/$dc" '.[$key] // empty' "$STATE_FILE")
            if [[ -n "$saved_replicas" ]]; then
                echo "Restoring dc/$dc in $ns to $saved_replicas replicas"
                oc scale dc "$dc" -n "$ns" --replicas="$saved_replicas"
            fi
        fi
    done

    # Handle Deployments
    for deploy in $(oc get deploy -n "$ns" -o jsonpath='{.items[*].metadata.name}'); do
        if [[ "$RESTORE_MODE" == false ]]; then
            replicas=$(oc get deploy "$deploy" -n "$ns" -o jsonpath='{.spec.replicas}')
            if [[ "$replicas" -gt 0 ]]; then
                echo "Scaling down deployment/$deploy in $ns from $replicas to 0"
                jq --arg ns "$ns" --arg name "$deploy" --argjson replicas "$replicas" \
                   '.[$ns + "/deploy/" + $name] = $replicas' "$STATE_FILE" > tmp.$$.json && mv tmp.$$.json "$STATE_FILE"
                oc scale deploy "$deploy" -n "$ns" --replicas=0
            fi
        else
            saved_replicas=$(jq -r --arg key "$ns/deploy/$deploy" '.[$key] // empty' "$STATE_FILE")
            if [[ -n "$saved_replicas" ]]; then
                echo "Restoring deployment/$deploy in $ns to $saved_replicas replicas"
                oc scale deploy "$deploy" -n "$ns" --replicas="$saved_replicas"
            fi
        fi
    done
done

# Finalize
if [[ "$RESTORE_MODE" == true ]]; then
    echo "Restoration complete."
    rm -f "$STATE_FILE"
else
    echo ""
    echo "===== COPY AND SAVE THE BELOW JSON FOR RESTORE ====="
    cat "$STATE_FILE"
    echo "===== END OF RESTORE JSON ====="
    rm -f "$STATE_FILE"
fi