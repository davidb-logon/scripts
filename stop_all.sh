  vm_name=$(mysql -D cloud -se "SELECT name FROM vm_instance WHERE state='Starting';")

    # Loop through each VM name and update its state to 'Stopped'
    for vm in $vm_name; do
        # Print the update statement and execute it
        echo "Updating VM: $vm"
        mysql -D cloud -e "UPDATE vm_instance SET state = 'Stopped' WHERE name = '$vm';"
       # virsh destroy $vm
    done 
