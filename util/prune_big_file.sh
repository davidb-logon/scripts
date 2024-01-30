#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials - Property of Log-On.
# (c) Copyright Log-On 2024.
# All Rights Reserved.
#------------------------------------------------------------------------------
# TODOs:

git filter-branch --force --index-filter \
"git rm --cached --ignore-unmatch pwdmgr-win/win/build/Build.sdf" \
--prune-empty --tag-name-filter cat -- --all
