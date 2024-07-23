#!/bin/bash

# Source script libraries as needed.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$DIR/lib/common.sh"

# Main script starts here
main() {
    init_vars "logon" "install_python_mkisof_mysql"

    start_logging
    logMessage "Updating package list..."
    do_cmd "sudo $INSTALL_CMD update"

    packages="$PKG_PYTHON_SETUPTOOLS $PKG_GENISOIMAGE $PKG_MYSQL_SERVER $PKG_PYTHON3_MYSQL_CONNECTOR $PKG_PYTHON3_MYSQLDB"
    for package in $packages; do 
        check_and_install_package $package
    done

    logMessage "Installation process completed."
}

init_vars() {

    init_utils_vars $1 $2
    detect_linux_distribution
    detect_install_cmd # exports INSTALL_CMD

    # Assuming LINUX_DISTRIBUTION is already set
    if [ "$LINUX_DISTRIBUTION" == "RHEL" ]; then
        # Red Hat package names
        PKG_PYTHON_SETUPTOOLS="python3-setuptools"
        PKG_GENISOIMAGE="genisoimage"
        PKG_MYSQL_SERVER="mariadb-server"
        PKG_PYTHON3_MYSQL_CONNECTOR="mysql-connector-python3"
        PKG_PYTHON3_MYSQLDB="python3-PyMySQL"
    else
        # Ubuntu package names
        PKG_PYTHON_SETUPTOOLS="python-setuptools"
        PKG_GENISOIMAGE="genisoimage"
        PKG_MYSQL_SERVER="mysql-server"
        PKG_PYTHON3_MYSQL_CONNECTOR="python3-mysql.connector"
        PKG_PYTHON3_MYSQLDB="python3-mysqldb"
    fi
}

main

 