#!/bin/bash

# Parse the JSON file and iterate over URLs
jq -r '.urls[]' urls.json | while read -r url; do
    # Extract the file name from the URL
    filename=$(basename "$url")
    
    # Download the tar file
    wget "$url" -O "$filename"
    
    # Extract the tar file
    tar -xvf "$filename"
    
    # Remove the tar file
    rm "$filename"
done