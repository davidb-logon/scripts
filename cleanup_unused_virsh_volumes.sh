#!/bin/bash

# Step 1: Get list of volumes used by all defined VMs
defined_vm_volumes=()

# Get all defined VMs
vm_list=$(virsh list --all --name)

# Loop through each VM and extract the disk volumes
for vm in $vm_list; do
  if [[ -n "$vm" ]]; then
    # Extract the XML configuration for the VM
    disk_file=$(virsh dumpxml "$vm" | grep "<source file=" | sed -n 's/.*file='\''\(.*\)'\''.*/\1/p')
    defined_vm_volumes+=($disk_file)
  fi
done

# Step 2: Get a list of all volumes from all storage pools
all_pools=$(virsh pool-list --all --name)

# Create an array for all available volumes
all_volumes=()

# Loop through all storage pools to list all volumes
for pool in $all_pools; do
  pool_volumes=$(virsh vol-list "$pool" --name)
  for volume in $pool_volumes; do
    if [[ -n "$volume" ]]; then
      # Get the full path to the volume
      volume_path=$(virsh vol-path "$volume" --pool "$pool")
      all_volumes+=($volume_path)
    fi
  done
done

# Step 3: Compare the lists and delete unused volumes
for vol in "${all_volumes[@]}"; do
  # Check if the volume is in the list of defined VM volumes
  if [[ ! " ${defined_vm_volumes[@]} " =~ " ${vol} " ]]; then
    # Volume not in use by any defined VM, delete it
    echo "Removing unused volume: $vol"
    virsh vol-delete "$vol" --pool "$(virsh vol-list --pool --name | grep "$vol")"
  fi
done

echo "Cleanup complete."
