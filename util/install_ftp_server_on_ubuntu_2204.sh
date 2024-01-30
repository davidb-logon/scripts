#!/bin/bash
sudo apt update
sudo apt install vsftpd
sudo systemctl enable vsftpd
sudo systemctl restart vsftpd

