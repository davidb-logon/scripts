#!/bin/bash

# Define variables
RPM_PATH="/data/repo/cloudstack-agent-4.19.1.0-1.s390x.rpm"
CLASS_PATH="com/cloud/hypervisor/kvm/resource/wrapper/LibvirtStartCommandWrapper.class"
OUTPUT_DIR="./output"
JAD_TOOL="/usr/bin/jad"  # Path to the 'jad' decompiler or you can use 'javap' if you prefer

# Ensure the output directory exists
mkdir -p "$OUTPUT_DIR"

# Install necessary tools
echo "Installing necessary tools..."
sudo yum install -y rpm2cpio cpio 

# Install Jad (Java decompiler) if not already installed
if [ ! -f "$JAD_TOOL" ]; then
    echo "Installing Jad decompiler..."
    wget http://www.varaneckas.com/jad/jad158e.linux.static.zip -O /tmp/jad.zip
    unzip /tmp/jad.zip -d /usr/local/bin/
    chmod +x /usr/local/bin/jad
    rm -f /tmp/jad.zip
    JAD_TOOL="/usr/local/bin/jad"
fi

# Extract the .class file from the RPM
echo "Extracting $CLASS_PATH from $RPM_PATH..."
rpm2cpio "$RPM_PATH" | cpio -idmv "./$CLASS_PATH" -D "$OUTPUT_DIR"

# Check if the class file was extracted
if [ ! -f "$OUTPUT_DIR/$CLASS_PATH" ]; then
    echo "Failed to extract $CLASS_PATH from $RPM_PATH"
    exit 1
fi

# Decompile the .class file
echo "Decompiling $CLASS_PATH to Java source..."
"$JAD_TOOL" -o -d "$OUTPUT_DIR" "$OUTPUT_DIR/$CLASS_PATH"

# Check if the decompilation was successful
JAVA_FILE="${OUTPUT_DIR}/${CLASS_PATH%.class}.java"
if [ -f "$JAVA_FILE" ]; then
    echo "Decompiled source saved to $JAVA_FILE"
else
    echo "Failed to decompile $CLASS_PATH"
    exit 1
fi
