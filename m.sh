#!/bin/bash

# Function to display the menu
display_menu() {
  local files=("$@")
  local cols=3
  local total_files=${#files[@]}
  local rows=$(( (total_files + cols - 1) / cols ))

  for (( i=0; i<rows; i++ )); do
    for (( j=0; j<cols; j++ )); do
      idx=$(( i + j * rows ))
      if [ $idx -lt $total_files ]; then
        printf "%2d) %-50s" $((idx+1)) "${files[$idx]}"
      fi
    done
    echo
  done
}

# Get the list of files and sort them by the numeric part of the filename
files=($(ls | grep -E '^[0-9]+_.*\.sh$' | sort -V))

# Display the menu
echo "Select a file to run:"
display_menu "${files[@]}"

# Get the user's choice
read -p "Enter the number of the file you want to run: " choice

# Validate the choice and run the selected file
if [[ $choice =~ ^[0-9]+$ ]] && [ $choice -ge 1 ] && [ $choice -le ${#files[@]} ]; then
  selected_file=${files[$((choice-1))]}
  echo "Running $selected_file..."
  ./$selected_file
else
  echo "Invalid choice. Exiting."
fi
