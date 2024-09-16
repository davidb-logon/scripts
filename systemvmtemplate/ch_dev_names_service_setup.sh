create_ch_dev_names_service() {
    # Create the systemd service file
    # Call the function to create the service
    # create_ch_dev_names_service
    # What This Does:
    # Service Unit File: The script creates a systemd service unit file (/etc/systemd/system/ch_dev_names.service).
    # After=systemd-udevd.service ensures the service runs only after systemd-udevd.service starts.
    # ExecStart=/root/ch_dev_names.sh runs the /root/ch_dev_names.sh script.
    # RemainAfterExit=yes keeps the service active even after the script has run, which is useful for one-shot services.
    # Enable the Service: The service is enabled to run on boot with systemctl enable.
    # Start the Service: The service is started immediately with systemctl start.
    # You can run the function in your environment to create the service, and your script should now run on boot right after systemd-udevd.service.

    cat <<EOF >/etc/systemd/system/ch_dev_names.service
[Unit]
Description=Run ch_dev_names script after udev
After=systemd-udevd.service
Requires=systemd-udevd.service

[Service]
Type=oneshot
ExecStart=/root/ch_dev_names.sh 2>&1 | tee >> /root/ch_dev_names.log3 # log-on addition
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd to recognize the new service
    systemctl daemon-reload

    # Enable the service to run on boot
    systemctl enable ch_dev_names.service

    # Start the service immediately
    systemctl start ch_dev_names.service

    echo "Service ch_dev_names.service created and started."
}

create_ch_dev_names_service