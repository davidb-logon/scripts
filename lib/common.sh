#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------
# Common bash functions to be reused in scripts

# Function to detect the Linux distribution and set the LINUX_DISTRIBUTION variable
detect_linux_distribution() {
    logMessage "--- Start to detect Linux distribution..."

    DIST=$(cat /etc/*release | grep ^ID= | awk -F= '{print $2}')
    case "$DIST" in
      "Ubuntu","mx","debian")
        export LINUX_DISTRIBUTION="UBUNTU"
        ;;
      "Red")
        export LINUX_DISTRIBUTION="RHEL"
        ;;
      *)
        export LINUX_DISTRIBUTION="Unknown"
        ;;
    esac


  # if grep -qEi 'ubuntu' /etc/*release; then
  #   export LINUX_DISTRIBUTION="UBUNTU"
  # elif grep -qEi 'red hat|rhel' /etc/*release; then
  #   export LINUX_DISTRIBUTION="RHEL"
  # else
  #   # Attempt to get the pretty name from /etc/os-release, if it exists
  #   if [ -f /etc/os-release ]; then
  #     # Extract the pretty name using grep and awk, removing quotes
  #     DISTRO_NAME=$(grep PRETTY_NAME /etc/os-release | awk -F= '{ print $2 }' | tr -d '"')
  #     # If DISTRO_NAME is not empty, set it, otherwise default to "Unknown"
  #     if [ ! -z "$DISTRO_NAME" ]; then
  #       export LINUX_DISTRIBUTION="$DISTRO_NAME"
  #     else
  #       export LINUX_DISTRIBUTION="Unknown"
  #     fi
  #   else
  #     export LINUX_DISTRIBUTION="Unknown"
  #   fi
  # fi
  logMessage "--- End of detecting Linux distribution, detected distribution: $LINUX_DISTRIBUTION"
}

exit_if_unsupported_distribution() {
    if [[ "$LINUX_DISTRIBUTION" != "UBUNTU" && "$LINUX_DISTRIBUTION" != "RHEL" ]]; then
        logMessage "Unsupported distribution: $LINUX_DISTRIBUTION. Exiting."
        exit 1
    fi
}

# Function using a case statement based on the LINUX_DISTRIBUTION variable
example_use_case() {
  case "$LINUX_DISTRIBUTION" in
    "UBUNTU")
      logMessage "--- Running Ubuntu specific commands..."
      # Add Ubuntu specific commands here
      ;;
    "RHEL")
      logMessage "--- Running RHEL specific commands..."
      # Add RHEL specific commands here
      ;;
    "Unknown")
      logMessage "--- Unknown Linux distribution, exiting"
      exit 1
      ;;    
    *)
      logMessage "Unknown Unsupported LINUX_DISTRIBUTION: $LINUX_DISTRIBUTION, exiting"
      exit 1
      ;;
  esac
}

exit_if_unsupported_distribution() {
  case "$LINUX_DISTRIBUTION" in
    "UBUNTU")
      logMessage "--- Running Ubuntu specific commands..."
      # Add Ubuntu specific commands here
      ;;
    "RHEL")
      logMessage "--- Running RHEL specific commands..."
      # Add RHEL specific commands here
      ;;
    "Unknown")
      logMessage "--- Unknown Linux distribution, exiting"
      exit 1
      ;;    
    *)
      logMessage "UnknowUnsupported LINUX_DISTRIBUTION: $LINUX_DISTRIBUTION, exiting"
      exit 1
      ;;
  esac
}


#check_if_connected_to_internet || exit 1
check_if_connected_to_internet() {
    ping -c 1 -W 5 "8.8.8.8" > /dev/null 2>&1 && return 0 || return 1
}

# Ensure the script is run as root, if not exists with message
check_if_root() {
    [ "$(id -u)" -eq 0 ] || { logMessage "ERROR: script must be run as root."; exit 1; }
}

check_if_ubuntu() {
    grep -qi 'ubuntu' /etc/os-release || { logMessage "ERROR: script is intended to run on Ubuntu only." >&2; exit 1; }
}

# confirm "are you sure" || exit 1
confirm() {
    read -p "$1 (y/n): " response  # Prompt the user with the message and (y/n) options
    case "$response" in
        [yY][eE][sS]|[yY])  # If the user responds with 'yes' or 'y' (case-insensitive)
            return 0  # True, in Bash a return value of 0 indicates success
            ;;
        *)
            return 1  # False, any non-zero return value indicates failure
            ;;
    esac
}

init_colors() {
    green="\033[32m"
    red="\033[31m"
    cyan="\033[0;36m"
    reset="\033[0m"
}

init_utils_vars() {
    init_colors

    SUFFIX=$(date +%Y%m%d_%H%M%S)
    project=${1:-"logon"} # Take 1st parameter or "logon"
    task="${2:-$(basename "${0%.sh}")}" # Take 2nd parameter or just the script name without the .sh
    filename="${task}_${SUFFIX}.log"
    LOGFILE="/var/log/$project/$filename"
    sudo mkdir -p "/var/log/$project"
    sudo chmod 777 "/var/log/$project"
}

logMessageToFile() {
    sudo echo "$(date "+%F %T")" "$@" >>"$LOGFILE"
}

logMessage() {
    local msg=${*,,} # Convert input parameters to lower case for string comparison
    [[ $msg == *"error"* ]] && color=$red || color=$green
    echo -e "${color}${*}${reset}"
    logMessageToFile "$@"
}

start_logging() {
    echo
    echo -e "${green}--- Logfile at: cat $LOGFILE ${reset}"
    logMessage "--- Start Script in directory: $(pwd)"
}

error_exit() {
    logMessage "ERROR: $1"
    exit 1
}

cleanup() {
    if $script_ended_ok; then 
        echo -e "$green"
        echo 
        echo "--- SCRIPT WAS SUCCESSFUL"
    else
        echo -e "$red"
        echo 
        echo "--- SCRIPT WAS UNSUCCESSFUL"
    fi
    echo "--- Logfile at: cat $LOGFILE"
    echo "--- End Script"
    echo -e "$reset"
}

check_if_remote_git_repo_exists() {
    local repo="$1"
    git ls-remote "$repo" &> /dev/null && return 0 || return 1
}

check_if_remote_git_branch_exists() {
    local repo="$1"
    local branch="$2"
    git ls-remote "$repo" "refs/heads/$branch" | grep -q "refs/heads/$branch" && return 0 || return 1
}

#check_if_connected_to_internet || exit 1
check_if_connected_to_internet() {
    ping -c 1 -W 5 "8.8.8.8" > /dev/null 2>&1 && return 0 || return 1
}

text_files_are_different() {
    cmp -s "$1" "$2" && return 1 || return 0
}



ensure_dir_does_not_exist() {
    local dir=$1
    logMessage "Ensuring $dir directory does not exist."
    if [ -d "$dir" ]; then
        if confirm "$dir exists, confirm removal [y/n]"; then
            sudo rm -rf "$dir"
            logMessage "Removed $dir"
        else
            error_exit "Removal of $dir was not approved."
        fi
    fi
} 

do_cmd() {
    local command="$1"
    local command_prefix=$(set -- $command; echo "$1 $2")
    local success_message="${2:-$command_prefix}"
    local error_or_info_message="${3:-$command_prefix}"

    logMessage "--- EXECUTE: $command"
    eval "$command"
    local rc=$?

    if [ "$rc" -eq 0 ]; then
        logMessage "--- SUCCESS: $success_message"
        return
    fi

    echo "error processinf"
    if [[ "${command:0:7}" == "result=" ]]; then
        detailed_error=", $result"
    fi

    if [[ $error_or_info_message == INFO:* ]]; then
        logMessage "--- INFO: ${error_or_info_message#INFO: }${detailed_error}"
        return "$rc"
    else
        logMessage "--- ERROR: $error_or_info_message${detailed_error}"
        exit 1
    fi
}

