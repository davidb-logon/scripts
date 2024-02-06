#!/bin/bash
if [ $# -eq 0 ]; then
    echo "Usage: print_files_times.sh <pattern>"
    exit 1  
fi
pattern="$1"

# Initialize an array to hold the output lines

declare -a lines

# Find files, filter, and process
while IFS= read -r file; do
    time=$(stat -c '%y' "$file" | cut -d '.' -f 1)  # Get modification time up to seconds
    name=$(basename "$file")
    lines+=("$time $name")  # Add the line to the array
done < <(find . -type f | grep $pattern)

# Sort the lines array and print each line
printf "%s\n" "${lines[@]}" | sort -k3

# Print the total number of files
echo "Total files: ${#lines[@]}"
