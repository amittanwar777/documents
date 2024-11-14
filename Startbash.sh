#!/bin/bash

# Variables
BUILD_NAME="buildname"
SOURCE_DIR="/path/to/source"
MAX_ATTEMPTS=10     # Maximum number of iterations
SLEEP_INTERVAL=10   # Wait time (in seconds) between each check

# Start the build with --follow to see logs in real-time
oc start-build "$BUILD_NAME" --from-dir="$SOURCE_DIR" --follow

# Get the latest build ID using the BuildConfig version
build_id=$(oc get bc "$BUILD_NAME" -o jsonpath='{.status.lastVersion}')
build_status=""

# Initialize attempt counter
attempt=0

# Check the status of the latest build in a loop
while [[ "$attempt" -lt "$MAX_ATTEMPTS" ]]; do
    # Get the current build status
    build_status=$(oc get build "${BUILD_NAME}-${build_id}" -o jsonpath='{.status.phase}')
    echo "Current build status: $build_status"

    # Check if the build is complete or has failed
    if [[ "$build_status" == "Complete" ]]; then
        echo "Build was successful. Proceeding with further steps..."
        # Add your push command here, e.g., pushing to an image repository
        exit 0
    elif [[ "$build_status" == "Failed" || "$build_status" == "Cancelled" ]]; then
        echo "Build failed or was cancelled."
        exit 1
    fi

    # Increment attempt counter and wait before the next check
    ((attempt++))
    echo "Attempt $attempt/$MAX_ATTEMPTS: Build still in progress. Checking again in $SLEEP_INTERVAL seconds..."
    sleep "$SLEEP_INTERVAL"
done

# If the loop completes without a final status
echo "Build did not complete within the maximum number of attempts. Current status: $build_status"
exit 1