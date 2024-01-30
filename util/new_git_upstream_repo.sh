#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------
# See usage for what this script does.
#------------------------------------------------------------------------------
# TODOs:

# Source script libraries as needed.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$DIR/lib/common.sh"

script_ended_ok=false
trap 'cleanup' EXIT

usage() {
cat << EOF
usage: 

new_git_upstream_repo <source_repo> <source_branch> <target_repo> <target_branch>
example:
new_git_upstream_repo   "https://github.com/apache/cloudstack.git" "4.19.0.0-RC20240122T1028" 
    "https://github.com/davidb-logon/cloudstack.git" "master"

This script creates a new local git repo cloned from <source_branch> from <source_repo>.
It renames it <target_branch>, pushes it to your <target_repo> on github, and
creates a remote "upstream" to the original <source_repo> to enable pull & merge from there.

This script assumes that: 
- You have an empty <target_repo> on github

It does the following:
- Clones the <source_repo> repo from github into current dir.
- cd's into the dir created.
- Checks out from git the <source_branch>.
- Renames it to <target_branch>.
- Sets remote "origin" to point to your empty repo.
- Pushes the local repo to "origin".
- Sets remote "upstream" to point to the <source_repo>.
  This allows you to fetch, pull and merge from the original when needed.
EOF
script_ended_ok=true
}

main() {
    init_vars "logon-cloudstack" "new_upstream_repo"
    start_logging
    parse_command_line_arguments "$@" # This also initializes the globals like $source_repo etc.
    validate_arguments
    clone_repo_and_cd_into_it $source_repo
    setup_remotes
    push_to_target
    script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
}

parse_command_line_arguments() {
    if [ $# != 4 ]; then
        usage
        exit
    fi
    source_repo="$1"
    source_branch="$2"
    target_repo="$3"
    target_branch="$4"  
}

validate_arguments() {
    check_if_remote_git_repo_exists "$source_repo" || error_exit "$source_repo not found"
    logMessage "Found source repo: $source_repo"
    check_if_remote_git_branch_exists "$source_repo" "$source_branch" || error_exit "Branch $source_branch not found in $source_repo"
    logMessage "Found source branch $source_branch in git repo: $source_repo"
    check_if_remote_git_repo_exists "$target_repo" || error_exit "$target_repo not found"
    logMessage "Found target git repo: $target_repo"
    check_if_remote_git_branch_exists "$target_repo" "$target_branch" && error_exit "Target branch '$target_branch' already exists in repo '$target_repo'. Repo should be empty."
    logMessage "Target repo does not contain branch $target_branch. Continuing."
}

do_cmd_example() {
     do_cmd  "command to execute" ["ok message" ["error message"]]
}

clone_repo_and_cd_into_it() {
    local repo=$1
    local clone_dir=$(basename -s .git "$repo") 
    ensure_dir_does_not_exist "$clone_dir"
    do_cmd "git clone -b $source_branch $source_repo"
    cd "$clone_dir"
}

remove_unneeded_large_files() {
    # You need to install the git filter-repo extension before using this.
    # Beware that removing files from git history messes up your ability to pull and merge later on from the same upstream repo.
    git filter-repo --path pwdmgr-win/win/build/Build.sdf --invert-paths --force
}

setup_remotes() {
    do_cmd "git remote rename origin upstream"
    do_cmd "git remote add origin $target_repo"
    do_cmd "git remote -v"
}

push_to_target() {
    do_cmd "git checkout -b $target_branch"
    do_cmd "git push -u origin $target_branch"
}

main "$@"
