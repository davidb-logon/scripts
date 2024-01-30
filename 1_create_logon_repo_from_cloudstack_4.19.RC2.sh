#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------
# This script invokes new_git_upstream_repo.sh to clone cloudstack 4.19 rc2 into
# your own github repo
#------------------------------------------------------------------------------

main() {
    init_vars 
    new_git_upstream_repo.sh "$source_repo" "$source_branch" "$target_repo" "$target_branch"
}

init_vars() {
    source_repo="https://github.com/apache/cloudstack.git"
    source_branch="4.19.0.0-RC20240129T1021"
    target_repo="https://github.com/davidb-logon/cloudstack.git"
    target_branch="master"
}

main "$@"
