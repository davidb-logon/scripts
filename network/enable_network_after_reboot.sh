#!/bin/bash

# Step 1: Ensure the script you want to run is executable
sudo chmod +x /data/scripts/network/net9.sh

# Step 2: Create a systemd service file to run the script after reboot
SERVICE_FILE="/etc/systemd/system/net9.service"

sudo bash -c "cat > $SERVICE_FILE" << EOF
[Unit]
Description=Enable Network After Reboot
After=network.target

[Service]
ExecStart=/data/scripts/network/net9.sh
Type=oneshot
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

# Step 3: Reload systemd to recognize the new service
sudo systemctl daemon-reload

# Step 4: Enable the service to start on boot
sudo systemctl enable net9.service

# Step 5: Start the service immediately (optional, to test the setup)
sudo systemctl start net9.service

echo "Systemd service 'net9' has been created and enabled to run on reboot."
