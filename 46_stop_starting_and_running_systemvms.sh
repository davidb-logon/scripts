#!/bin/bash

# Function to update VM state in the database
update_vm_state() {
  local vm_name="$1"
  echo "Updating state of VM: $vm_name to Stopped..."
  mysql -D cloud -se "UPDATE vm_instance SET state='Stopped' WHERE name='$vm_name';"
  if [ $? -eq 0 ]; then
    echo "State of $vm_name updated to 'Stopped'."
  else
    echo "Failed to update the state of $vm_name."
  fi
}

# Fetch VM names and states from the database, each separated by a newline
vm_name_and_state=$(mysql -D cloud -se "SELECT name, state FROM vm_instance;")

# Process each line by reading the VM name and state
echo "$vm_name_and_state" | while read -r vm_name vm_state; do
  # Display the current VM name and state
  echo "VM: $vm_name is currently in state: $vm_state."

  # Ask user for confirmation to update the state
  read -p "Do you want to update the state of $vm_name to 'Stopped'? (y/n): " choice

  # If user confirms, update the state
  if [[ $choice == "y" || $choice == "Y" ]]; then
    update_vm_state "$vm_name"
  else
    echo "Skipped updating $vm_name."
  fi
done

echo "Script completed."
