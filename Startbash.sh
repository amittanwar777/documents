#!/bin/bash

# Variables
BUILD_NAME="buildname"
SOURCE_DIR="/path/to/source"

# Start the build with --follow to see logs in real-time and capture the build ID
build_id=$(oc start-build "$BUILD_NAME" --from-dir="$SOURCE_DIR" --follow -o name | awk -F'/' '{print $2}')

# After the build completes, get the final status
build_status=$(oc get build "$build_id" -o jsonpath='{.status.phase}')

# Evaluate the build status
if [[ "$build_status" == "Complete" ]]; then
    echo "Build was successful. Proceeding with further steps..."
    # Add your push command here, e.g., pushing to an image repository
elif [[ "$build_status" == "Failed" ]]; then
    echo "Build failed."
    exit 1
else
    echo "Build did not complete successfully. Current status: $build_status"
    exit 1
fi