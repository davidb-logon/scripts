#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials - Property of Log-On.
# (c) Copyright Log-On Systems & Communication Ltd. 2023.
# All Rights Reserved.
#------------------------------------------------------------------------------
# TODOs: 

script_ended_ok=false
# Get the directory of the current script
#DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# Source our wave libraries
#source "$DIR/wavemenu.sh"

trap 'cleanup' EXIT

main() {
    init_vars
    create_clean_temp_dir
    parse_command_line_arguments "$@"
    get_keystore_password_from_user
    get_key_file_from_user_if_not_defined
    get_key_file_from_PKCS12_store_if_not_defined
    create_temp_PKCS12_key_store_with_certificate_and_private_key
    print_vars
    list_temp_keystore_to_log
    backup_open_liberty_current_keystore
    stop_openliberty_and_wave_services
    delete_the_default_alias_from_open_liberty_keystore
    import_temp_keystore_with_certificate_and_private_key_into_open_liberty_keystore
    list_final_open_liberty_keystore_to_log
    start_openliberty_and_wave_services
    print_final_messages_to_user
}

init_vars() {
    green="\033[32m"
    red="\033[31m"
    cyan="\033[0;36m"
    reset="\033[0m"

    SUFFIX=$(date +%Y%m%d_%H%M%S)
    LOGFILE=/var/log/WAVE/install_cert_"${SUFFIX}".log 
    
    WAVE_PROPERTIES_FILE="/usr/wave/install/liberty-bootstrap02.properties" # This should contain the Open Libetry keystore name and type
    check_file_exists $WAVE_PROPERTIES_FILE
    WAVE_JNLP_FILE="/usr/wave/GUI/WAVE.jnlp"
    check_file_exists $WAVE_JNLP_FILE
    LIBERTY_KEYSTORE_FILENAME=$(extract_property "wave.liberty.keystore.filename" $WAVE_PROPERTIES_FILE) # key.jks or key.p12
    LIBERTY_KEYSTORE_TYPE=$(extract_property "wave.liberty.keystore.type" $WAVE_PROPERTIES_FILE) # jks or PKCS12
    LIBERTY_KEYSTORE_DIR=/usr/wave/websphere/wlp/usr/servers/defaultServer/resources/security
    LIBERTY_KEYSTORE_PATH="$LIBERTY_KEYSTORE_DIR/$LIBERTY_KEYSTORE_FILENAME" 
    TEMP_DIR="/tmp/wave_cert_tmp_${SUFFIX}"
    LIBERTY_KEYSTORE_BACKUP_FILE="$TEMP_DIR/$LIBERTY_KEYSTORE_FILENAME.backup" 
    TEMP_KEYSTORE_FILE="$TEMP_DIR/key.p12"
    TEMP_PEM_FILE="$TEMP_DIR/private_key_and_certificate.pem"
    TEMP_KEY_FILE="$TEMP_DIR/private.key"
    TEMP_CMD_FILE="$TEMP_DIR/temp_cmd_file".txt # do_cmd regenerates this file for every command
    TEMP_CRT_TXT="$TEMP_DIR/temp_crt.txt"
}

print_vars() {
    logMessageToFile ""
    logMessageToFile "Variables used in this run:"
    logMessageToFile "================================================================================================="
    logMessageToFile "--- KEY_FILE=$KEY_FILE"
    logMessageToFile "--- CERT_FILE=$CERT_FILE"
    logMessageToFile "--- CERT_BUNDLE_FILE=$CERT_BUNDLE_FILE" 
    logMessageToFile "--- WAVE_PROPERTIES_FILE=$WAVE_PROPERTIES_FILE"
    logMessageToFile "--- WAVE_JNLP_FILE=$WAVE_JNLP_FILE"
    logMessageToFile "--- LIBERTY_KEYSTORE_DIR=$LIBERTY_KEYSTORE_DIR"
    logMessageToFile "--- LIBERTY_KEYSTORE_PATH=$LIBERTY_KEYSTORE_PATH"
    logMessageToFile "--- LIBERTY_KEYSTORE_TYPE=$LIBERTY_KEYSTORE_TYPE"
    logMessageToFile "--- LIBERTY_KEYSTORE_BACKUP_FILE=$LIBERTY_KEYSTORE_BACKUP_FILE"
    logMessageToFile "--- TEMP_DIR=$TEMP_DIR"
    # logMessageToFile "--- TEMP_KEY_FILE=$TEMP_KEY_FILE"           
    # logMessageToFile "--- TEMP_PEM_FILE=$TEMP_PEM_FILE"
    # logMessageToFile "--- TEMP_CMD_FILE=$TEMP_CMD_FILE"
    logMessageToFile "--- TEMP_KEYSTORE_FILE=$TEMP_KEYSTORE_FILE"
    logMessageToFile "================================================================================================="
    logMessageToFile ""
}

usage() {
cat << EOF
-------------------------------------------------------------------------------
Import a CA signed certificate into the OpenLiberty keystore that was created
when you've installed the Log-On Wave server. 

Before running this script, you must have the following:

    1.  The CA signed certificate file you were provided by your organization.
    2.  The private key file OR the PKCS12 keystore file that was used to 
        generate the CSR for your certificate.
    3.  The password for the Open Liberty keystore.

You can run this script in one of two ways:
		
    1.  ./install_cert.sh <certificate file> <private key file> 
        The script will install the given certificate using the private 
        key provided.
		    
    2.  ./install_cert.sh <certificate file>
        The script will prompt you for the private key file. If you don't have
        it, the script will attempt to extract the private key from the PKCS12 
        keystore that was used to generate the CSR.

Notes:
    1.  If you don't have the private key file, but have the PKCS12 keystore,
        the script will prompt you for it's password. This password must be 
        the same as the one used for the Open Liberty keystore.  
    2.  The script creates a backup of your Open Liberty keystore before
        modifying it. It displays the path to the backup file.
    3.  The script logs it's activity to a log file in /var/logs/WAVE/
-------------------------------------------------------------------------------
EOF
script_ended_ok=true
}

#--- Helper functions ---------------------------------------------------------

logMessageToFile() {
    echo "$(date "+%F %T")" "$@" >>"$LOGFILE"
}

logMessage() {
    local msg=${*,,} # Convert input parameters to lower case for string comparison
    [[ $msg == *"error"* ]] && color=$red || color=$green
    echo -e "${color}${*}${reset}"
    logMessageToFile "$@"
}


do_cmd() {
    local command="$1"
    local command_prefix=$(set -- $command; echo "$1 $2")
    local success_message="${2:-$command_prefix}"
    local error_or_info_message="${3:-$command_prefix}"

    logMessageToFile "Doing: $command &> $TEMP_CMD_FILE"
    eval "$command &> $TEMP_CMD_FILE"
    local rc=$?

    if [ "$rc" -eq 0 ]; then
        logMessage "--- SUCCESS: $success_message"
        return
    fi

    logMessage "--- The following is command output:"
    cat "$TEMP_CMD_FILE"
    cat "$TEMP_CMD_FILE" >> "$LOGFILE"

    if [[ $error_or_info_message == INFO:* ]]; then
        logMessage "--- INFO: ${error_or_info_message#INFO: }"
        return "$rc"
    else
        logMessage "--- ERROR: $error_or_info_message"
        exit 1
    fi
}



# Function to extract a property value
extract_property() {
    local key=$1
    local file=$2
    local value
    value=$(grep "^${key}=" "$file")

    if [ -z "$value" ]; then
        logMessage "--- ERROR: Key '$key' not found in $file."
        exit 1
    fi
    echo "${value#*=}"
}

start_logging() {
    echo
    echo -e "${green}--- Start Script in directory: $(pwd)${reset}"
    echo -e "${green}--- Logfile at: $LOGFILE ${reset}" 
}

parse_command_line_arguments() {
    if [[ $# -lt 1 || $# -gt 2 ]]; then
        usage
        exit
    fi

    start_logging

    CERT_FILE="$1"
    logMessage "--- Installing certificate file: $CERT_FILE"
    check_file_exists "$CERT_FILE"
    check_if_certificate_is_valid "$CERT_FILE"

    if [[ $# -eq 2 ]]; then
        KEY_FILE="$2"
        logMessage "--- Installing private key file $KEY_FILE"
        check_file_exists "$KEY_FILE"
        check_if_key_is_valid "$KEY_FILE"
        check_if_private_key_matches_certificate "$KEY_FILE" "$CERT_FILE"
    fi
}

check_file_exists() {
    if [ ! -f "$1" ]; then
        logMessage "--- ERROR: File '$1' not found."
        exit 1
    fi
}

check_if_key_is_valid() {
    local key_file="$1"
    do_cmd  "openssl rsa -in $key_file -check" \
            "Key file: $key_file is valid." \
            "Key file: $key_file is not a valid RSA key file."
}

check_if_private_key_matches_certificate() {
    local key_file="$1"
    local cert_file="$2"
    crt_md5=$(openssl x509 -noout -modulus -in "$cert_file" | openssl md5)
    key_md5=$(openssl rsa -noout -modulus -in "$key_file" | openssl md5)
    # echo "$key_md5", "$crt_md5"
    if ! [ "$crt_md5" = "$key_md5" ]; then 
        logMessage "--- ERROR: private key $key_file MD5 stamp does not match certificate $cert_file."
        exit 1
    fi
}

print_items() {
    local pattern="$1"
    local input_file="$2"
    local singular_form="$3"
    local plural_form="$4"
    local items=($(grep -oP "$pattern" "$input_file"))
    local num_items=${#items[@]}

    if (( num_items == 0 )); then
        echo "No $plural_form in certificate."
    elif (( num_items == 1 )); then
        echo -e "$singular_form: $green${items[0]}$reset"
    else
        echo "$num_items $plural_form in certificate:"
        for i in "${!items[@]}"; do
            echo -e "  $(($i + 1)): $green${items[i]}$reset"
        done
    fi
}

extract_url_or_ip_from_jnlp() {
    file=$1
    # Extracting the first argument
    argument=$(grep '<argument>' "$WAVE_JNLP_FILE" | head -1 | awk -F '>' '{print $2}' | awk -F '<' '{print $1}')

    # Determine if the argument is an IP address or a URL
    if [[ $argument =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        ip_address=$argument
        echo "$ip_address"
    else
        url=$argument
        echo "$url"
    fi          
}

display_certificate_summary() {
    if [ "$#" -eq 0 ]; then
        logMessage "ERROR: Can't display certificate, no certificate file given"
    fi

    cert_txt="$1"

    not_before=$(grep 'Not Before' "$cert_txt" | awk '{print $3 " " $4 ", " $6}')
    not_after=$(grep 'Not After' "$cert_txt" | awk '{print $4 " " $5 ", " $7}')
    issuer=$(grep 'Issuer:' "$cert_txt" | sed 's/.*CN=\([^,]*\).*/\1/')
    
    echo 

    title="Certificate Summary for $green$CERT_FILE$reset:"
    echo -e $title
    echo -e "Valid from: $green$not_before$reset   Expires on: $green$not_after$reset   Issuer: $green$issuer$reset" 

    ip_pattern='IP Address:\K\d+(\.\d+){3}'
    print_items "$ip_pattern" "$cert_txt" "IP Address" "IP Addresses"

    dns_pattern='DNS:\K[a-zA-Z0-9-\.]+(?=,|\s|$)'
    print_items "$dns_pattern" "$cert_txt" "Domain" "Domains"

    echo

    echo -e -n "Current host ip address: $cyan"
    ip -4 -o a | grep -oP --color=never 'inet \K[\d\.]+' | grep -v '^127\.0\.0\.1$'
    echo -e -n "$reset"
    echo -e    "Current host domain:     $cyan"$(hostname -f)"$reset"
    echo -e    "URL from WAVE.jnlp:      $cyan"$(extract_url_or_ip_from_jnlp)"$reset"
}


check_if_certificate_is_valid() {
    local cert_file="$1"
    openssl x509 -in "$cert_file" -text -noout > "$TEMP_CRT_TXT"
    rc=$?
    if [ "$rc" = 0 ]; then
        display_certificate_summary "$TEMP_CRT_TXT"
        
        read -p "Proceed with certificate installation on this host? (y/n):" answer
        if [[ $answer = [Yy]* ]]; then
            logMessage "--- SUCCESS: certificate file: $cert_file is a valid certificate."
        else
            logMessage "--- ERROR: certificate file: $cert_file not confirmed."
            exit 1
        fi
    else
       logMessage "--- ERROR: certificate file: $cert_file is not a valid certificate file."
       exit 1
    fi
}

get_key_file_from_user() {
    read -p "No key file provided. Do you have the private key file that was used to generate the CSR (y/n)?" answer
    if [[ $answer = [Yy]* ]]; then
        read -p "Enter the full path of your private key file: " KEY_FILE
        if [[ -n "$KEY_FILE" ]] && [[ -f "$KEY_FILE" ]]; then
            check_if_key_is_valid "$KEY_FILE"
            check_if_private_key_matches_certificate "$KEY_FILE" "$CERT_FILE"
        else
            logMessage "--- ERROR: KEY_FILE: $KEY_FILE does not exist."
            exit 1
        fi
    fi
}

get_key_file_from_PKCS12_keystore() {
    read -p "Do you have the PKCS12 keystore that was used to create your CSR (y/n)? " answer
    if [[ $answer = [Yy]* ]]; then
        read -p "Enter the full path of your keystore: " keystore_file
        if [[ -f "$keystore_file" ]]; then
            # Extract the private key and certificate to a PEM file
            do_cmd "openssl pkcs12 -in $keystore_file -out $TEMP_PEM_FILE -nodes -password pass:$KEYSTORE_P12_PASSWORD" \
                   "Extracted private key and certificate to a temp PEM file." "Unable to extract key and certificate from $keystore_file."

            # Extract just the private key to a separate file
            do_cmd  "openssl pkey -in $TEMP_PEM_FILE -out $TEMP_KEY_FILE" \
                    "Extracted private key from PEM file to $TEMP_KEY_FILE" "Unable to extract private key from PEM file: $TEMP_PEM_FILE."
            KEY_FILE="$TEMP_KEY_FILE"
            check_if_private_key_matches_certificate "$KEY_FILE" "$CERT_FILE" 
        else
            logMessage "--- ERROR: Keystore file not found."
            exit 1
        fi
    else
        logMessage "--- ERROR: No PKCS12 keystore or private key file provided."
        exit 1
    fi
}

get_keystore_password_from_user() {
    read -s -p "Enter the Open Liberty keystore password: " password
    echo
    LIBERTY_PASSWORD="$password"

    # Check if password is valid, allow user to re-enter if not
    while ! do_cmd "keytool -list -v -keystore $LIBERTY_KEYSTORE_PATH -storepass $LIBERTY_PASSWORD -storetype $LIBERTY_KEYSTORE_TYPE" "Password is valid." "INFO: Password incorrect. Retry."; do
        read -s -p "Enter the Open Liberty keystore password: " password
        echo
        LIBERTY_PASSWORD="$password"
    done

    KEYSTORE_P12_PASSWORD="$password"
}

create_temp_PKCS12_key_store_with_certificate_and_private_key() {
    CERT_BUNDLE_FILE=""
    echo
    echo "Sometimes a certificate bundle is provided as well. A certificate bundle may contain"
    echo "intermediate certificates and root certificate in your certificate's trust chain."
    read -p "Do you have a certificate bundle file? (y/n): " answer
    if [[ $answer = [Yy]* ]]; then
        read -p "Enter the certificate bundle file path: " CERT_BUNDLE_FILE
        check_file_exists "$CERT_BUNDLE_FILE"
        CERT_BUNDLE_OPTION="-CAfile $CERT_BUNDLE_FILE -caname root"
    else
        CERT_BUNDLE_OPTION=""
    fi

    do_cmd "openssl pkcs12 -export -in $CERT_FILE -inkey $KEY_FILE -out $TEMP_KEYSTORE_FILE -name default -password pass:$KEYSTORE_P12_PASSWORD  $CERT_BUNDLE_OPTION" \
           "Creating PKCS12 keystore at: $TEMP_KEYSTORE_FILE" \
           "Unable to create PKCS12 keystore at: $TEMP_KEYSTORE_FILE"
}

#------------------------------------------------------------------------------
get_key_file_from_user_if_not_defined() {
    if [ "$KEY_FILE" = "" ]; then
        get_key_file_from_user
    fi
}

get_key_file_from_PKCS12_store_if_not_defined() {
    if [ "$KEY_FILE" = "" ]; then
        get_key_file_from_PKCS12_keystore
    fi
}

create_clean_temp_dir() {
    mkdir -p "$TEMP_DIR"
    if ! [ $? = 0 ]; then
        logMessage "--- ERROR: unable to create working directory at: $TEMP_DIR"
        exit 1
    fi
}

list_temp_keystore_to_log() {
    keytool -list -v -keystore "$TEMP_KEYSTORE_FILE" -storetype PKCS12 -storepass "$KEYSTORE_P12_PASSWORD" >> "$LOGFILE"
}


backup_open_liberty_current_keystore() {
    do_cmd  "cp -p $LIBERTY_KEYSTORE_PATH $LIBERTY_KEYSTORE_BACKUP_FILE" \
            "OpenLiberty keystore backed up to $LIBERTY_KEYSTORE_BACKUP_FILE" \
            "Unable to backup OpenLiberty keystore at: $LIBERTY_KEYSTORE_PATH"
}

stop_openliberty_and_wave_services() {
    echo "To install the certificate, the services of the OpenLiberty Web server"
    echo "and the Wave server (BTS) must be stopped. They will be restarted"
    echo "after the certificate has been imported."
    read -p "Stopping OpenLiberty Web Server and Wave Server. Confirm (y/n)? :" answer
    if [[ $answer = [Yy]* ]]; then
        systemctl stop WAVEBackgroundServices
        systemctl stop WAVEWebServer
        logMessage "--- Services stopped"
    else
        logMessage "--- ERROR: user did not confirm stopping services, exiting."
        exit 1
    fi
}

start_openliberty_and_wave_services() {
    logMessage "--- Restarting services."
    systemctl start WAVEWebServer
    systemctl start WAVEBackgroundServices
    logMessage "--- OpenLiberty Web Server and Wave Server services were restarted."
}

delete_the_default_alias_from_open_liberty_keystore() {
    logMessage "--- Deleting the alias 'default' from the open liberty store"
    do_cmd  "keytool -delete -alias default -v -storepass $LIBERTY_PASSWORD -keystore $LIBERTY_KEYSTORE_PATH -storetype $LIBERTY_KEYSTORE_TYPE" \
            "Alias 'default' was deleted." "INFO:Alias 'default' did not exist in keystore $LIBERTY_KEYSTORE_PATH"
}

import_temp_keystore_with_certificate_and_private_key_into_open_liberty_keystore() {
    logMessage "--- Importing the temp keystore into the OpenLiberty keystore"
    do_cmd  "keytool -importkeystore -srckeystore $TEMP_KEYSTORE_FILE -srcstoretype PKCS12 -srcstorepass $KEYSTORE_P12_PASSWORD \
               -destkeystore $LIBERTY_KEYSTORE_PATH -deststorepass $LIBERTY_PASSWORD -deststoretype $LIBERTY_KEYSTORE_TYPE" \
            "Imported temp PKCS12 keystore with private key and certificate into OpenLiberty keystore." \
            "Unable to import the temp PKCS12 keystore into the OpenLiberty keystore."
}

list_final_open_liberty_keystore_to_log() {
    keytool -list -v -keystore "$LIBERTY_KEYSTORE_PATH" -storepass "$LIBERTY_PASSWORD" -storetype "$LIBERTY_KEYSTORE_TYPE" >> "$LOGFILE"
}

print_final_messages_to_user() {
    script_ended_ok=true
    echo -e "$green"
    echo 
    echo "--- IMPORT WAS SUCCESSFUL"
    echo "--- Temp directory at: $TEMP_DIR can be removed, if no longer needed. It still contains the keystore backup."
    echo "--- Logfile at: cat $LOGFILE"
    echo "--- End Script"
    echo -e "$reset"
}

cleanup() {
    if $script_ended_ok; then 
        return
    fi
    echo -e "$red"
    echo 
    echo "--- IMPORT WAS UNSUCCESSFUL"
    echo "--- Logfile at: cat $LOGFILE"
    echo "--- End Script"
    echo -e "$reset"
}
    
main "$@"