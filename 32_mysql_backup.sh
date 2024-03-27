#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------

main() {
    start_time=$(date +%s)
    usage
    init_vars "logon" "cloudstack"
    parse_command_line_arguments "$@"
    start_logging

    # Insert script logic here
    cat << EOF
    1. Create a backup of the mysql database
    2. List all backups
    3. Restore the backup

EOF

    read -p "Please enter your choice: " choice
    case $choice in
        1)
            create_backup        
            ;;
        2)
            list_backups
            ;;
        3)
            restore_backup
            ;;
        *)
            logMessage "Invalid choice. Exiting."
            exit 1
            ;;
    esac


    end_time=$(date +%s)
    elapsed_time=$((end_time - start_time))
    logMessage "The script took $elapsed_time seconds to complete."
    script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
    BACKUP_DIR="/home/sefi/mysql_backup"
}
restore_backup() {
    #!/bin/bash

# Set the folder path
folder=$BACKUP_DIR

# Check if the folder exists
if [ ! -d "$folder" ]; then
    echo "Folder not found."
    exit 1
fi

# Change directory to the specified folder
cd "$folder" || exit 1

# List files in the folder with numbers
counter=1
for file in *; do
    echo "$counter. $file"
    ((counter++))
done

# Prompt user to enter the number of the file
read -p "Enter the number of the file you want to select: " choice

# Validate user input
if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
    echo "Invalid input. Please enter a number."
    exit 1
fi

# Check if the selected number is within range
if (( choice < 1 || choice >= counter )); then
    echo "Invalid choice. Please enter a number within the range."
    exit 1
fi

# Get the selected file name
selected_file=$(ls | sed -n "${choice}p")

echo "You selected: $selected_file"

#do_cmd("zcat $BACKUP_DIR/$selected_file \| mysql -ucloud -pcloud cloud")

}

list_backups() {
    do_cmd "ls -l $BACKUP_DIR"
}
create_backup() {
    do_cmd "mkdir -p $BACKUP_DIR"
    do_cmd "mysqldump --add-drop-table -ucloud -pcloud cloud | gzip -c > $BACKUP_DIR/cloudstack-full-backup-$(date +%Y%m%d_%H%M%S).sql.gz"
}
parse_command_line_arguments() {
    # if [[ $# -lt 1 || $# -gt 2 ]]; then
    #     usage
    #     exit
    # fi
    temp=1
}

usage() {
cat << EOF
-------------------------------------------------------------------------------
This script 
-------------------------------------------------------------------------------
EOF
script_ended_ok=true
}

#-------------------------------------------------------#
#                Start script execution                 #
#-------------------------------------------------------#

# Source script libraries as needed.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$DIR/lib/common.sh"

script_ended_ok=false
trap 'cleanup' EXIT

main "$@"
