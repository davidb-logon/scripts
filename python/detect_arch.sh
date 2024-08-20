#!/bin/bash

FILE="$1"

if [ -z "$FILE" ]; then
    echo "Usage: $0 <filename>"
    exit 1
fi

echo "Detecting architecture for $FILE..."

# Try starting the file with QEMU and extract the architecture from the output
ARCH=$(qemu-system-x86_64 -machine none -cpu help 2>&1 | grep -i "$FILE")

if [[ $ARCH =~ "x86_64" ]]; then
    ARCHITECTURE="x86_64 (AMD64)"
elif [[ $ARCH =~ "i386" ]]; then
    ARCHITECTURE="i386 (x86)"
elif [[ $ARCH =~ "aarch64" ]]; then
    ARCHITECTURE="aarch64 (ARM64)"
elif [[ $ARCH =~ "s390x" ]]; then
    ARCHITECTURE="s390x (IBM System z)"
elif [[ $ARCH =~ "ppc64" ]]; then
    ARCHITECTURE="ppc64 (PowerPC 64)"
else
    ARCHITECTURE="Unknown"
fi

echo "Architecture: $ARCHITECTURE"

# Terminate the QEMU process (if it started)
pkill -f qemu-system-x86_64

echo "QEMU process terminated."
