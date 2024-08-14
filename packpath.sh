#!/bin/bash

# Split the PATH by ':' and convert it to an array
IFS=':' read -r -a path_array <<< "$1"

# Use awk to remove duplicates while preserving order
unique_path=$(printf "%s\n" "${path_array[@]}" | awk '!seen[$0]++' | paste -sd ':' -)

# Set the cleaned PATH
#export PATH="$unique_path"

# Print the cleaned PATH
echo "Cleaned PATH: $unique_path"
