#!/bin/sh
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
#       5. Export the certificate to a certificate file <hostname>.cer
#       6. Delete any certificate with alias="default" from the OpenLiberty keystore.
#       7. Import the certificate <hostname>.cer into OpenLiberty's keystore.
#       8. Notify user of the certificate file path
#
#-------------------------------------------------------------------------------------------------------------------------------

main() {
  check_arguments_and_initialize $@
  create_output_directory
  start_logging
  print_variables
  generate_certificate_in_temporary_keystore
  export_certificate
  delete_default_alias_from_openLiberty_keystore
  import_certificate_into_OpenLiberty_keystore
  notify_user_of_certificate_file_location
}

function check_arguments_and_initialize() {
  OUTPUT_DIR="/root/self_signed_certificate"
  CERT_NAME=$(hostname)
  LIBERTY_KEYSTORE_PATH="/usr/wave/websphere/wlp/usr/servers/defaultServer/resources/security/key.jks"

  PASSWORD=$1
  LOGFILE=$2

  if test -z $PASSWORD; then
    echo "Usage: wave_create_certificate.sh <password to OpenLiberty keystore> <optional log file path>"
    exit 1
  fi

  if test -z $LOGFILE; then
    CURDATE=$(date_prefix)
    LOGFILE_SUFFIX=${CURDATE//:/-}
    LOGFILE=${OUTPUT_DIR}"/create_wave_certificate"${LOGFILE_SUFFIX}".log"
    touch $LOGFILE
  fi
}

function start_logging() {
  logMessage "START running create_wave_certificate.sh"
}

function print_variables() {
   logMessage "Log file: "$LOGFILE
   logMessage "Output directory: "$OUTPUT_DIR
   logMessage "Certificate name: "$CERT_NAME
   logMessage "Liberty keystore path: "$LIBERTY_KEYSTORE_PATH
}

function create_output_directory() {
  mkdir -p $OUTPUT_DIR
  cd $OUTPUT_DIR
  rm -f keystore.p12
  rm -f *.log
  rm -f *.cer
  logMessage "Created and cleaned directory:" $OUTPUT_DIR
}

function generate_certificate_in_temporary_keystore() {
  keytool -genkey -storepass $PASSWORD -alias default \
          -keyalg RSA \
          -keypass $PASSWORD \
          -keystore keystore.p12 \
          -storetype PKCS12 \
          -ext san=dns:$CERT_NAME \
          -validity 3650 \
          -dname "CN="$CERT_NAME",OU=Wave,O=Log-On Software LTD,L=Ramat Gan,ST=NA,C=IL"
  check_return_code $? "Certificate generation"
}

function export_certificate() {
  keytool -export -storepass $PASSWORD -alias default \
          -file $CERT_NAME.cer \
          -keystore keystore.p12 \
          -storetype PKCS12
  check_return_code $? "Certificate export"
}

function delete_default_alias_from_openLiberty_keystore() {
  keytool -delete -alias default -v -storepass $PASSWORD \
          -keystore $LIBERTY_KEYSTORE_PATH
  if [ $? = 0 ]; then
    logMessage "Certificate removal from Liberty's keystore was successful"
  fi
}

function import_certificate_into_OpenLiberty_keystore() {
  keytool -importkeystore -deststorepass $PASSWORD -srcstorepass $PASSWORD \
          -destkeystore $LIBERTY_KEYSTORE_PATH \
          -srckeystore $OUTPUT_DIR/keystore.p12 \
          -srcstoretype PKCS12
  check_return_code $? "Certificate import to Liberty's keystore"
}

function notify_user_of_certificate_file_location() {
  logMessage "END running wave_create_certificate.sh successfully"
  logMessage "The new self-signed certificate can be found at: ${OUTPUT_DIR}/${CERT_NAME}.cer"
}
#---------------------------
# Utility functions
#---------------------------

function date_prefix(){
  echo $(date +%F_%T) # Sample result value: 2018-12-12_06:55:49
}

function logMessage() {
  msg=$(date_prefix)" -- $@"
  echo $msg
  echo $msg >> $LOGFILE
}

function check_return_code() {
  rc=$1
  msg=$2
  if [ $1 = 0 ]; then
    logMessage "$2 was successful"
  else
    logMessage "$2 failed, rc = "$1
    exit 1
  fi
}

main $@
