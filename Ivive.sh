#!/bin/bash

# List of bounded contexts
contexts=("fw" "fw-sl" "ca" "ca-sl" "ca-gl")

# Loop through each context
for context in "${contexts[@]}"; do
    # Check if the context is "fw" or starts with "fw-"
    if [[ "$context" == "fw" || "$context" == "fw-"* ]]; then
        folder="valpre"
    else
        # Extract the part before the hyphen (if any)
        folder="${context%%-*}"
    fi

    # Print the result (or perform other actions)
    echo "Bounded Context: $context --> Folder Name: $folder"
done