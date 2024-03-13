#!/bin/bash

directory="/home/davidb/logon/scripts" 

find_next_available_number() {
    directory="/home/davidb/logon/scripts"  
    prefix_pattern="[0-9]+_"  # Regex pattern to match numbers followed by an underscore

    highest_number=0

    # Loop through files that match the prefix pattern
    for file in "$directory"/*; do
        if [[ -f "$file" ]]; then  # Check if it's a regular file
            filename=$(basename -- "$file")  # Extract just the filename

            # Use a regular expression to extract the number prefix
            if [[ $filename =~ ^([0-9]+)_ ]]; then
                number=${BASH_REMATCH[1]}  # Extract the number from the regex match

                # Check if this number is higher than the highest found so far
                if (( number > highest_number )); then
                    highest_number=$number
                fi
            fi
        fi
    done

    # Next available number is one more than the highest found
    next_available_number=$((highest_number + 1))

    echo "$next_available_number"
}

if [[ $# -lt 1 ]]; then
    echo "--- Usage: 0_copy_template.sh <script_name without a number>"
    echo "--- example: 0_copy_template.sh install_cmk"
    echo "--- This will copy the template into scripts directory with the given name prepended with the next number."
    exit
fi

n=$(find_next_available_number)
echo "Copying ${directory}/template.sh to ${directory}/${n}_$1"
cp -pv ${directory}/template.sh ${directory}/${n}_$1
