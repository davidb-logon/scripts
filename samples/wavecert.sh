#!/bin/bash
#----------------------------------------------------------------------------------------
# Licensed Materials - Property of Log-On.
# (c) Copyright Log-On Systems & Communication Ltd. 2023.
# All Rights Reserved.
#
#----------------------------------------------------------------------------------------
# This script makes it easy to manage the SSL certificate options for Wave. You
# can select from a simple text-based menu the following operations:
#
# 1. Create a self-signed-certificate and import it into the OpenLiberty keystore.
#    This allows SSL encryption between client and server,
#    but requires certificate installation on the workstations.
#
# 2. Use your own certificate and import it into the OpenLiberty keystore.
#    This is the preferred option, since it is secure and usually alleviates the need to
#    install the certificate on the workstations.
#
# 3. Allow Wave to work without a certificate.
#    This is the least secure option, but the easiest to set up. It can be used as
#    a temporary solution until a more secure option is needed.
#
# Usage notes
# a. The script should be run as root.
# b. The script requires the password of the existing OpenLiberty keystore. If
#    you don't have it, you can select the option: "Create new keystore and password"
#    This will backup the existing keystore (if any), and create a new OpenLiberty
#    keystore with a new password that you will be prompted provide.
#    This typically is a non-issue, since OpenLiberty only stores the
#    certificate for Wave's use.
# c. The script will notify you of the certiciate full path so that
#    you can import it to the Wave workstation and install it.
# d. The script operations are logged. The script will notify you the log file
#    location.
#
#----------------------------------------------------------------------------------------

function temp() {
    # just an area to write some notes
    #====================================
    # curent state https://linux3.wave.log-on.com/  working good
    # Alias name: default
    # Entry type: keyEntry
    # Owner: CN=linux3.wave.log-on.com, OU=Wave, O=Log-On Software LTD, L=Ramat Gan, ST=NA, C=IL
    # Valid from: 3/23/22 10:17 AM until: 3/20/32 10:17 AM
    #          SHA1: q
    "c:\Program Files\Java\jre-1.8\bin\keytool.exe" -list -keystore "c:\Program Files\Java\jre-1.8\lib\security\cacerts" -storepass changeit
    ls -l /mnt/linuxu/cer/linux3.wave.log-on.com/linux3.wave.log-on.com.cer
    echo -n "Enter password: "
    read -s -r password

    openssl pkcs12 -in /mnt/linuxu/cer/linux3.wave.log-on.com/keystore.p12 -out private_key_and_certificate.pem -nodes -passin pass:"$password"
    openssl pkcs12 -export -in private_key_and_certificate.pem -out keystore.p12 -name "default" -passout pass:"$password"

    keytool -importkeystore -srckeystore keystore.p12 -srcstoretype PKCS12 -destkeystore key.jks -deststoretype JKS

    keytool -list -keystore keystore.jks -storepass liberty!
    keytool -J-Dkeystore.pkcs12.legacy -importkeystore -srckeystore tovmeod.pfx -srcstoretype pkcs12 -srcalias 1 -srcstorepass liberty! -destkeystore keystore.jks -deststorepass liberty! -destalias tovmeod -deststoretype pkcs12
    keytool -list -keystore keystore.jks -storepass liberty!
    keytool -importkeystore -srckeystore keystore.jks -destkeystore keystore.jks -deststoretype pkcs12
    keytool -v -importkeystore -srckeystore keystore.jks -destkeystore keystore.p12 -deststoretype PKCS12
    keytool -importkeystore -srckeystore keystore.p12 -srcstoretype PKCS12 -destkeystore new_keystore.jks -deststoretype JKS
    keytool -importkeystore -srckeystore keystore.jks -destkeystore upload-keystore.jks -deststoretype pkcs12
    keytool -list -keystore upload-keystore.jks -storepass liberty!
    keytool -list -keystore keystore.jks -storepass liberty!
    awk -v RS='-----END CERTIFICATE-----' '{print $0 "-----END CERTIFICATE-----" > "certificate" NR ".crt"}' yourfile.pem

    #Get-Content -Raw -Path "C:\Path\To\Your\File.pem" | foreach { $_ -replace '\r\n', "`n" } -split '-----END CERTIFICATE-----' | ForEach-Object { $_ + '-----END CERTIFICATE-----' | Out-File -FilePath ("C:\Path\To\Output\Certificate{0}.crt" -f $script:i++) }

    # Alias name: default
    # Creation date: Nov 13, 2023
    # Entry type: keyEntry
    # Certificate chain length: 1
    # Certificate[1]:
    # Owner: CN=linux3.wave.log-on.com, OU=Wave, O=Log-On Software LTD, L=Ramat Gan, ST=NA, C=IL
    # Issuer: CN=linux3.wave.log-on.com, OU=Wave, O=Log-On Software LTD, L=Ramat Gan, ST=NA, C=IL
    # Serial number: 29efd33b
    # Valid from: 3/23/22 10:17 AM until: 3/20/32 10:17 AM

    #Warning:
    #The JKS keystore uses a proprietary format. It is recommended to migrate to PKCS12
    #which is an industry standard format using
    keytool -importkeystore -srckeystore /usr/wave/openliberty/wlp/usr/servers/defaultServer/resources/security/key.jks \
        -destkeystore /usr/wave/openliberty/wlp/usr/servers/defaultServer/resources/security/key.jks -deststoretype pkcs12

    CERT_NAME=temp
    PASSWORD=temp123
    FILE=

    keytool -genkey -storepass $PASSWORD -alias default1 \
        -keyalg RSA \
        -keypass $PASSWORD \
        -keystore keystore.p12 \
        -storetype PKCS12 \
        -ext san=dns:$CERT_NAME \
        -validity 3650 \
        -dname "CN=$CERT_NAME,OU=Wave,O=Log-On Software LTD,L=Ramat Gan,ST=NA,C=IL"

    keytool -importcert -storepass $PASSWORD -keystore keystore.p12 \
        -file "$FILE" \
        -alias default \
        -storetype PKCS12

    keytool -importkeystore -deststorepass $PASSWORD -srcstorepass $PASSWORD \
        -destkeystore keys.jks \
        -srckeystore keystore.p12 \
        -srcstoretype PKCS12
    has context menu

    curl https://aboutssl.org/java-keytool-commands/

}

main() {
    check_if_root
    initialize_logging
    start_logging
    menu1
}

function check_if_root() {
    # Check if the script is run by the root user
    if [[ $(uname) == *"MINGW"* ]]; then
        return
    else
        if [[ $EUID -ne 0 ]]; then
            echo "This script must be run as root."
            exit 1
        fi
    fi
}
chHead() {
    chHead=" Ver 20231121"
}
function menuw() {
    readarray -t menuw <<EOF
Windows SSL Certificate helper 1.0 © 2023 Log-On Software LTD.$chHead@chHead
1=List certificate@wListCertificate
r=Return@menu1
q=Quit@quit
EOF
    pmenu "${menuw[@]}"
}

function wListCertificate() {

    echo "$JAVA_HOME"
    #ls -l "/c/Program Files/Java/jre-1.8/lib/security"
    "c:\Program Files\Java\jre-1.8\bin\keytool.exe" -list -keystore "c:\Program Files\Java\jre-1.8\lib\security\cacerts" -storepass changeit
}

function menu1() {
#ic=Install certificate@mainic "$@"  # for relese 2.0.0.6 i took it out of the menu
    readarray -t menu1 <<EOF
SSL Certificate helper 1.0 © 2023 Log-On Software LTD.$chHead@chHead

1=Load user certificate@load_user_certificate
11=Load user certificate2@load_user_certificate2
12=convert p12 to pem@convertP12Pem
2=Create self signed certificate@create_self_signed
3=Menu to Allow working w/o certificate@jnlpmenu
4=Restart Wave services@restart_wave
5=less messages.log@less /usr/wave/openliberty/wlp/usr/servers/defaultServer/logs/messages.log
6=Display cert info@displayInfoFromCrt
7=List aliases in jks@listAliases
8=Work on windows side@menuw
9=Bash shell@bash
g=WaveGit@./wavegit.sh
q=Quit@quit
EOF
    pmenu "${menu1[@]}"
}

function convertP12Pem() {
    p12Path="/mnt/linuxu/cer/linux3.wave.log-on.com/keystore.p12"
    LIBERTY_KEYSTORE_PATH="/usr/wave/websphere/wlp/usr/servers/defaultServer/resources/security/key.jks"
    p12PathDir=$(dirname "$p12Path")

    openssl pkcs12 -in "$p12Path" -out "$p12PathDir/private_key_and_certificate.pem" -nodes -passin pass:"$PASSWORD"
    rm -f keystore.p12
    openssl pkcs12 -export -in private_key_and_certificate.pem -out keystore.p12 -name "default" -passout pass:"$PASSWORD"
    keytool -delete -keystore $LIBERTY_KEYSTORE_PATH -storepass $PASSWORD -alias "default"
    keytool -importkeystore -srckeystore keystore.p12 -srcstoretype PKCS12 -destkeystore $LIBERTY_KEYSTORE_PATH -deststoretype PKCS12 -srcstorepass $PASSWORD -storepass $PASSWORD -alias "default"

    listAliases
}

function convertCertificate() {

    #Export the Certificate from the Keystore:
    LIBERTY_KEYSTORE_PATH="/usr/wave/websphere/wlp/usr/servers/defaultServer/resources/security/key.jks"
    keytool -export -keystore $LIBERTY_KEYSTORE_PATH -storepass $PASSWORD -alias "default" -file certificate.cer
    #Replace your_alias with the alias of the entry you want to convert.

    #Delete the Existing Entry:

    keytool -delete -keystore $LIBERTY_KEYSTORE_PATH -storepass $PASSWORD -alias "default"

    #Import the Certificate and Private Key as a KeyEntry:

    #-deststoretype pkcs12
    keytool -importkeystore -srckeystore $LIBERTY_KEYSTORE_PATH -destkeystore $LIBERTY_KEYSTORE_PATH -srcalias "default" -destalias "default" -storepass $PASSWORD

    #This command will prompt you to enter the keystore password and the password for the private key.

    #Convert the PKCS12 Keystore Back to JKS (Optional):
    #If you need the keystore in JKS format after the conversion, you can use the following command:

    keytool -importkeystore -srckeystore $LIBERTY_KEYSTORE_PATH -srcstoretype pkcs12 -destkeystore $LIBERTY_KEYSTORE_PATH -deststoretype jks -storepass $PASSWORD
    #Now, your keystore entry should be a "keyEntry" with both the private key and the associated certificate. Adjust the commands according to your keystore structure and entry details.

    #Remember to replace your_alias with the actual alias of the entry you want to convert. If you are unsure about the aliases in your keystore, you can list them using the following command:

    keytool -list -keystore $LIBERTY_KEYSTORE_PATH -storepass $PASSWORD

}
function listAliases() {
    ask_for_openliberty_password
    echo
    keytool -list -v -keystore /usr/wave/openliberty/wlp/usr/servers/defaultServer/resources/security/key.jks \
        -storepass $PASSWORD | grep 'Alias\|Entry\|Owner\|Valid\|SHA1:\|DNSName:\|Keystore'
}

function displayInfoFromCrt() {
    MAX_TRIES=3
    Count=0

    logMessage "Start loading user certificate"
    local count=0

    while true; do
        ((count++))
        read -r -p "$count) Please provide the full path of your certificate file: " CERT_FILE_NAME
        if [ -e "$CERT_FILE_NAME" ]; then
            echo "Certificate file found: $CERT_FILE_NAME"
            break
        fi

        if [ "$count" -ge "$MAX_TRIES" ]; then
            echo "Exceeded maximum tries. Certificate file not found."
            return
        fi

        echo "The file \"$CERT_FILE_NAME\" does not exist"
    done
    openssl x509 -inform DER -outform PEM -in "$CERT_FILE_NAME" -out certificate.pem
    openssl x509 -in certificate.pem -noout -text
}
function wave_services() {
    case "$1" in
    start)
        prefix="Starting"
        cmd="start"
        ;;
    stop)
        prefix="Stopping"
        cmd="stop"
        ;;
    restart)
        prefix="Restarting"
        cmd=restart
        ;;
    *)
        echo "Usage: wave_services {start|stop|restart}"
        exit 1
        ;;
    esac
    for service in "WAVEWebServer" "WAVEBackgroundServices"; do
        msg="$prefix $service"
        logMessage "$msg"
        systemctl $cmd $service
        check_return_code $? "$msg"
    done
}

function restart_wave() {
    logMessage "Restarting Wave Web server and Wave Background services"
    systemctl restart WAVEWebServer
    systemctl restart WAVEBackgroundServices
}

function start_wave() {
    wave_services start
}

function stop_wave() {
    wave_services stop
}

function load_user_certificate() {
    logMessage "Start loading user certificate"
    read -r -p "Please provide the full path of your certificate file: " CERT_FILE_NAME
    while ! [ -e "$CERT_FILE_NAME" ]; do
        echo "The file $CERT_FILE_NAME does not exist"
        read -r -p "Please provide the full path of your certificate file: " CERT_FILE_NAME
    done

    LIBERTY_KEYSTORE_PATH="/usr/wave/websphere/wlp/usr/servers/defaultServer/resources/security/key.jks"
    ask_for_openliberty_password
    delete_default_alias_from_openLiberty_keystore "$LIBERTY_KEYSTORE_PATH"
    #rm -f $LIBERTY_KEYSTORE_PATH
    import_certificate_into_OpenLiberty_keystore_from_file
    logMessage "Import was a success. Please restart Wave services."

}

function load_user_certificate2() {
    logMessage "Start loading user certificate"
    read -r -p "Please provide the full path of your certificate file: " CERT_FILE_NAME
    while ! [ -e "$CERT_FILE_NAME" ]; do
        echo "The file $CERT_FILE_NAME does not exist"
        read -r -p "Please provide the full path of your certificate file: " CERT_FILE_NAME
    done

    LIBERTY_KEYSTORE_PATH="/usr/wave/websphere/wlp/usr/servers/defaultServer/resources/security/keyt.jks"
    LIBERTY_KEYSTORE_PATH2="/usr/wave/websphere/wlp/usr/servers/defaultServer/resources/security/key.jks"
    #ask_for_openliberty_password
    #delete_default_alias_from_openLiberty_keystore "$LIBERTY_KEYSTORE_PATH"
    #delete_default_alias_from_openLiberty_keystore "$LIBERTY_KEYSTORE_PATH2"
    rm -f $LIBERTY_KEYSTORE_PATH
    keytool -importcert -file "$CERT_FILE_NAME" -keystore "$LIBERTY_KEYSTORE_PATH" -storepass $PASSWORD -alias "default" -noprompt &>/dev/null #-storetype pkcs12
    check_return_code $? "Certificate import of user file to Liberty's keystore"
    rm -f $LIBERTY_KEYSTORE_PATH2
    keytool -importkeystore -srckeystore $LIBERTY_KEYSTORE_PATH -destkeystore $LIBERTY_KEYSTORE_PATH2 \
        -srcstoretype jks -srcstorepass $PASSWORD -deststorepass $PASSWORD #-deststoretype jks
    #  -deststoretype PKCS12
    #  keytool -importkeystore  -destkeystore /usr/wave/websphere/wlp/usr/servers/defaultServer/resources/security/key.jks \
    #  -srckeystore /mnt/linuxu/cer/linux3.wave.log-on.com/keystore.p12 -srcstoretype PKCS12  \
    #  -srcstorepass 'liberty!'  -deststorepass 'liberty!'

    logMessage "Import was a success. Please restart Wave services."
}

function jnlpmenu() {
    readarray -t jnlpm <<EOF
Change how Wave will use a certificate$chHead@chHead
1=Show current state@jnlpState
2=Force Wave to use a certificate@enableCertificate
3=Allow Wave to work w/o certificate@disableCertificate
4=View WAVE.jnlp file@less +G /usr/wave/GUI/WAVE.jnlp
r=Return@menu1
q=Quit@quit
EOF
    pmenu "${jnlpm[@]}"
}
function jnlpState() {
    # tail -n 7 /usr/wave/GUI/WAVE.jnlp | head -n 5
    readarray -t lines < <(tail -n 10 /usr/wave/GUI/WAVE.jnlp)
    # Print the content stored in the array
    # i=1
    # for line in "${lines[@]}"; do
    #   echo $i "$line"
    #   ((i++))
    # done
    # echo "${lines[5]}"
    # echo "${lines[@]}"
    if echo "${lines[@]}" | grep -Pq '<!--.*?60000.*?-->'; then
        #if grep -Pzq '<!--.*?60000.*?-->' /usr/wave/GUI/WAVE.jnlp; then
        echo "Wave requires a certificate."
    else
        echo "Wave does not require a certificate."

    fi

}

function enableCertificate() {
    file="/usr/wave/GUI/WAVE.jnlp"
    sed -i -e 's/<argument>trustanybtscert<\/argument>/<argument>trustanybtscert<\/argument>  -->/g' $file
    sed -i 's/during Wave installation. -->/during Wave installation./g' $file
    jnlpState
}

function disableCertificate() {
    file="/usr/wave/GUI/WAVE.jnlp"
    sed -i -e '/<argument>trustanybtscert<\/argument>/{N;s/-->//}' $file
    sed -i 's/during Wave installation.$/during Wave installation. -->/g' $file
    jnlpState
}

#-----------------------------------------------------------------------------------------------------------------------------
#     This script creates a self-signed certificate for use by: the OpenLiberty webserver, Wave BTS, and Wave GUI clients.
#
#     Parameters:
#       $1 Password for the OpenLiberty keystore.
#       $2 Path to logfile (optional)
#
#     What it does:
#       1. Check arguments and initialize variables
#       2. Create output dir /root/self_signed_certificate & cd into it.
#       3. Generate self-signed certificate, with san=dns:<hostname> and CN=<hostname>
#       4. Place certificate in temp keystore "keystore.p12" with alias="default" .
#       5. Export the certificate to a certificate file <hostname>.crt
#       6. Delete any certificate with alias="default" from the OpenLiberty keystore.
#       7. Import the certificate <hostname>.crt into OpenLiberty's keystore.
#       8. Notify user of the certificate file path
#
#-------------------------------------------------------------------------------------------------------------------------------

function create_self_signed() {
    logMessage "Start creating self-seigned certificate"
    check_arguments_and_initialize "$@"
    create_output_directory
    print_variables
    generate_certificate_in_temporary_keystore
    export_certificate
    delete_default_alias_from_openLiberty_keystore
    import_certificate_into_OpenLiberty_keystore
    notify_user_of_certificate_file_location
}

function check_arguments_and_initialize() {
    var=$(grep argument /usr/wave/GUI/WAVE.jnlp | head -n 1)
    CERT_NAME=$(echo "$var" | grep -oP '(?<=<argument>).*?(?=</argument>)')
    ip_regex="^([0-9]{1,3}\.){3}[0-9]{1,3}$"

    if [[ $CERT_NAME =~ $ip_regex ]]; then
        echo "Generating IP address: $CERT_NAME"
        dnsip="ip"
    else
        echo "Generating for domain name: $CERT_NAME"
        dnsip="dns"
    fi

    #CERT_NAME=$(hostname)
    CERT_FILE_NAME=$CERT_NAME.crt
    LIBERTY_KEYSTORE_PATH="/usr/wave/websphere/wlp/usr/servers/defaultServer/resources/security/key.jks"
    OUTPUT_DIR="/root/self_signed_certificate"
    #PASSWORD=""
    ask_for_openliberty_password
}
# This function ensures that there is an openLiberty keystore, and that user has a password to it.
function prepare_keystore() {
    if [ -e "$LIBERTY_KEYSTORE_PATH" ]; then
        confirm "Found openLiberty's keystore. Do you have its password?" && {
            ask_for_openliberty_password
            return $?
        }
        echo "Use option 5 in the menu to create a new OpenLiberty keystore."
        return 1
    fi
}
function ask_for_openliberty_password() {
    MAX_TRIES=3
    for ((i = 0; i <= MAX_TRIES; i++)); do
        read -r -p "Please enter Open Liberty's keystore password: " PASSWORD
        is_password_valid "$PASSWORD" && return 0
    done
    echo "More than $MAX_TRIES attempts. Use option 5 in the menu to create a new OpenLiberty keystore."
    return 1
}

function is_password_valid() {
    #keytool -list -storepass $1 -keystore $LIBERTY_KEYSTORE_PATH &> /dev/null
    rc=1
    if [ -n "$PASSWORD" ]; then
        keytool -list -v -keystore /usr/wave/openliberty/wlp/usr/servers/defaultServer/resources/security/key.jks -storepass "$PASSWORD" &>/dev/null
        rc=$?
        if ! [ "$rc" = 0 ]; then
            echo "Incorrect password."
        fi
    fi
    return $rc
}

function create_self_signed_main() {
    logMessage "Start creating self-seigned certificate"
    check_arguments_and_initialize "$@"
    create_output_directory
    print_variables
    generate_certificate_in_temporary_keystore
    export_certificate
    delete_default_alias_from_openLiberty_keystore
    import_certificate_into_OpenLiberty_keystore
    notify_user_of_certificate_file_location
}
function create_new_keystore() {
    echo "Creating a new OpenLiberty keystore involves the following steps: "
    echo "  1. Stopping the Wave BTS and Wave Web server. "
    echo "  2. Backing up the existing keystore and removing it."
    echo "  3. Asking for a new keystore password. "
    echo "  4. Encrypting the password and saving it for OpenLiberty and Wave's use."
    echo "  5. Restarting Wave Web Server, which will create the new keystore."
    confirm "Do you wish to continue?" || return
    stop_wave

    # Check if keystore exists. If yes, take a backup
    if [ -e $LIBERTY_KEYSTORE_PATH ]; then
        logMessage "Backing up OpenLiberty key store file $LIBERTY_KEYSTORE_PATH"
        BACKUP_DIR="$OUTPUT_DIR/openLiberty_keystore_backup"
        CURDATE=$(date_prefix)
        SUFFIX=${CURDATE//:/-}
        BACKUP_FILE="$BACKUP_DIR/key.jks.$SUFFIX.backup"
        mkdir -p $BACKUP_DIR
        cp "$LIBERTY_KEYSTORE_PATH" "$BACKUP_FILE"
        logMessage "OpenLiberty key store was backed up to: $BACKUP_FILE"
        rm -f $LIBERTY_KEYSTORE_PATH
        logMessage "OpenLiberty key store was deleted."
    fi
    if [ -f /usr/wave/install/set-keystore-password.sh ]; then
        source /usr/wave/install/set-keystore-password.sh liberty "$LOGFILE"
    fi
}
function initialize_logging() {
    if test -z "$LOGFILE"; then
        CURDATE=$(date_prefix)
        LOGFILE_SUFFIX=${CURDATE//:/-}
        LOGFILE="/var/log/cert_actions_${LOGFILE_SUFFIX}.log"
        touch "$LOGFILE" 2>/dev/null
    fi
}

function start_logging() {
    logMessage "Log file: $LOGFILE"
}

function print_variables() {
    logMessage "Output directory: $OUTPUT_DIR"
    logMessage "Certificate name: $CERT_NAME"
    logMessage "Liberty keystore path: $LIBERTY_KEYSTORE_PATH"
}

function create_output_directory() {
    mkdir -p "$OUTPUT_DIR"
    if [ -d "$OUTPUT_DIR" ]; then
        cd "$OUTPUT_DIR" || echo "$OUTPUT_DIR not found" exit 1
        rm -f keystore.p12
        rm -f ./*.log
        rm -f ./*.crt
        logMessage "Created and cleaned directory:" $OUTPUT_DIR
    else
        logMessage "ERROR: Unable to create directory:" $OUTPUT_DIR
        exit 1
    fi
}

function generate_certificate_in_temporary_keystore() {
    echo in: generate_certificate_in_temporary_keystore
    pwd
    keytool -genkey -storepass "$PASSWORD" -alias default \
        -keyalg RSA \
        -keypass "$PASSWORD" \
        -keystore keystore.p12 \
        -storetype PKCS12 \
        -ext san="$dnsip:$CERT_NAME" \
        -validity 3650 \
        -dname "CN=$CERT_NAME,OU=Wave,O=Log-On Software LTD,L=Ramat Gan,ST=NA,C=IL"
    check_return_code $? "Certificate generation"
}

function export_certificate() {
    keytool -export -storepass "$PASSWORD" -alias default \
        -file "$CERT_FILE_NAME" \
        -keystore keystore.p12 \
        -storetype PKCS12
    check_return_code $? "Certificate export"
}

function delete_default_alias_from_openLiberty_keystore() {
    if [ -n "$1" ]; then
        keytool -delete -alias default -v -storepass "$PASSWORD" \
            -keystore "$1" &>/dev/null
        if [ $? = 0 ]; then
            logMessage "Certificate removal from Liberty's keystore was successful"
        else
            logMessage "Alias 'default' does not exist, will be created."
        fi
    fi
}

function import_certificate_into_OpenLiberty_keystore() {
    keytool -importkeystore -deststorepass "$PASSWORD" -srcstorepass "$PASSWORD" \
        -destkeystore "$LIBERTY_KEYSTORE_PATH" \
        -srckeystore "$OUTPUT_DIR/keystore.p12" \
        -srcstoretype PKCS12
    check_return_code $? "Certificate import to Liberty's keystore"
}

function import_certificate_into_OpenLiberty_keystore_from_file() {
    keytool -importcert -file "$CERT_FILE_NAME" -keystore "$LIBERTY_KEYSTORE_PATH" -storepass "$PASSWORD" -alias "default" -noprompt -deststoretype jks &>/dev/null
    check_return_code $? "Certificate import of user file to Liberty's keystore"
}

function notify_user_of_certificate_file_location() {
    logMessage "END running wave_create_certificate.sh successfully"
    logMessage "The new self-signed certificate can be found at: ${OUTPUT_DIR}/${CERT_FILE_NAME}"
}
#---------------------------
# Utility functions
#---------------------------

function date_prefix() {
    date +%F_%T # Sample result value: 2018-12-12_06:55:49
}

function logMessage() {
    msg=$(date_prefix)" -- $*"
    echo "$msg"
    echo "$msg" /dev/null >>"$LOGFILE"
}

function check_return_code() {
    rc=$1
    msg=$2
    if [ "$1" = 0 ]; then
        logMessage "$2 was successful"
    else
        logMessage "$2 failed, rc = $1"
        exit 1
    fi
}

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

mainic() {
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
#cat << EOF
readarray -t usage1 << EOF
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
echo
printBlueBlock 80 "${usage1[@]}"
echo
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
    usage
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

#mainic "$@"



if [ -f "wavecert.var" ]; then
    . wavecert.var
fi

# Get the directory of the current script
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# Source our wave libraries
source "$DIR/wavemenu.sh"
#. wavemenu.sh

main
