#!/bin/bash
FILE="$1"
# Start QEMU in the background
echo "@@@@@@ $FILE" > carch.out
qemu-system-s390x -drive file=$FILE,format=qcow2 -nographic  >> carch.out &
#qemu-system-s390x -drive file=$FILE,format=qcow2 -nographic | sed  -r 's/\x1b\[[0-9;]*[a-zA-Z]//g' | tee > carch.out &

# Get the PID of the last background process (QEMU)
QEMU_PID=$!

# Wait for 3 seconds
sleep 3

# Kill the QEMU process
kill $QEMU_PID
cat carch.out | sed  -r 's/\x1b\[[0-9;]*[a-zA-Z]//g' | >> carchs.out
cat carch.out | sed  -r 's/\x1b\[[0-9;]*[a-zA-Z]//g' 
echo "QEMU process $QEMU_PID terminated after 3 seconds."
