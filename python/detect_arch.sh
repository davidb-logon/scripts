#!/bin/bash

# Check if the file name is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <file_name>"
    exit 1
fi

FILE=$1

# Check if the file exists
if [ ! -f "$FILE" ]; then
    echo "File not found: $FILE"
    exit 1
fi

# Function to detect architecture using qemu
detect_architecture() {
    OUTPUT=$(qemu-system-x86_64 -cpu help 2>&1 | grep -Eo 'qemu-system-[a-z0-9_]+')

    if echo "$OUTPUT" | grep -q "qemu-system-x86_64"; then
        echo "Architecture: x86_64"
    elif echo "$OUTPUT" | grep -q "qemu-system-aarch64"; then
        echo "Architecture: ARM"
    elif echo "$OUTPUT" | grep -q "qemu-system-ppc64"; then
        echo "Architecture: PowerPC"
    elif echo "$OUTPUT" | grep -q "qemu-system-s390x"; then
        echo "Architecture: s390x"
    else
        echo "Architecture: Unknown"
    fi
}

# Attempt to start the file with QEMU in a non-blocking way and then detect architecture
echo "Detecting architecture for $FILE..."
(qemu-system-x86_64 -nographic -curses -snapshot "$FILE" &) > /dev/null 2>&1
detect_architecture

# Kill the QEMU process
pkill -f qemu-system-x86_64

echo "QEMU process terminated."
