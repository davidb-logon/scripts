#!/bin/bash

# Function to update VM state in the database
update_vm_state() {
  local vm_name=$1
  echo "Updating state of VM: $vm_name to Stopped..."
  mysql -D cloud -se "UPDATE vm_instance SET state='Stopped' WHERE name='$vm_name';"
  if [ $? -eq 0 ]; then
    echo "State of $vm_name updated to 'Stopped'."
  else
    echo "Failed to update the state of $vm_name."
  fi
}

# Fetch VM names and states from the database
vm_name_and_state=$(mysql -D cloud -se "SELECT name, state FROM vm_instance;")

# Convert the result into an array by splitting on spaces
IFS=' ' read -r -a vm_array <<< "$vm_name_and_state"

# Loop through the array and display the VM name and state
for ((i=0; i<${#vm_array[@]}; i+=2)); do
  vm_name=${vm_array[i]}
  vm_state=${vm_array[i+1]}

  # Ask user for confirmation to update the state
  echo "VM: $vm_name is currently in state: $vm_state."
  read -p "Do you want to update the state of $vm_name to 'Stopped'? (y/n): " choice

  # If user confirms, update the state
  if [[ $choice == "y" || $choice == "Y" ]]; then
    update_vm_state "$vm_name"
  else
    echo "Skipped updating $vm_name."
  fi
done

echo "Script completed."
