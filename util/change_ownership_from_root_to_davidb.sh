#!/bin/bash

# Define your username
YOUR_USERNAME="davidb"


# Use find and xargs with sudo to change permissions recursively,
# but only in directories containing "target" in the path
sudo find . -type f -exec bash -c '
  file="$0"
  if [[ "$(stat -c %U "$file")" == "root" ]]; then
    sudo chown "$YOUR_USERNAME:$YOUR_USERNAME" "$file"
    sudo chmod u+rw "$file"
    echo "Changed permissions for $file"
  fi
' {} \;
