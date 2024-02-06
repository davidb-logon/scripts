#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------
# Common bash functions to be reused in scripts

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
        return
    fi
    echo -e "$red"
    echo 
    echo "--- SCRIPT WAS UNSUCCESSFUL"
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

    logMessage "Doing: $command"
    eval "$command"
    local rc=$?

    if [ "$rc" -eq 0 ]; then
        logMessage "--- SUCCESS: $success_message"
        return
    fi

    if [[ $error_or_info_message == INFO:* ]]; then
        logMessage "--- INFO: ${error_or_info_message#INFO: }"
        return "$rc"
    else
        logMessage "--- ERROR: $error_or_info_message"
        exit 1
    fi
}

