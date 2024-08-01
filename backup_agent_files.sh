
#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------
backup_agent_files() {
    files=( 
        "/etc/cloudstack/agent/agent.properties" 
        "/etc/cloudstack/agent/cloud.ca.crt" 
        "/etc/cloudstack/agent/cloud.crt" 
        "/etc/cloudstack/agent/cloud.csr" 
        "/etc/cloudstack/agent/cloud.jks" 
        "/etc/cloudstack/agent/cloud.key" 
        "/etc/cloudstack/agent/environment.properties" 
        "/etc/cloudstack/agent/log4j-cloud.xml" 
     )

    backup_dir="/home/davidb/logon/work/agent-backup"
    mkdir -p "$backup_dir"

    # Loop through the files
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            # Extract base name
            base_name=$(basename "$file")

            # Get current date and time
            datetime=$(date +"%Y%m%d-%H%M%S")

            # Construct backup file path
            backup_file="$backup_dir/${base_name%.*}-$datetime.${base_name##*.}"

            # Copy the file to the backup directory with the new name
            sudo cp -pv "$file" "$backup_file"

            echo "Backed up '$file' to '$backup_file'"
        else
            echo "File '$file' does not exist and was not backed up."
        fi
    done

}

backup_agent_files