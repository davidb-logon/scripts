#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: remove_files.sh <pattern>"
    exit 1  
fi
pattern="$1"
find . -type f -name '*-sources.jar' -exec sudo rm -f {} +