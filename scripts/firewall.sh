#!/bin/bash
# Define your local network
# Eg 192.168.1.0/24
LOCAL_IP="192.168.x.x/24"

# ========= Firewall Ports =========
echo "Installing UFW..."
sudo apt-get install -y ufw

# UFW status
echo "UFW status..."
UFW_STATUS=$(sudo ufw status | grep -i "Status: active")

if [ -z "$UFW_STATUS" ]; then
    echo "UFW is not active. Enabling it now..."
    sudo ufw enable
else
    echo "UFW is already active."
fi

# Now (re)check status to be sure it's enabled before adding rules
if sudo ufw status | grep -iq "Status: active"; then
    echo "Applying firewall rules..."

    # Allow SSH from local IP
    sudo ufw allow proto tcp from "$LOCAL_IP" to any port 22

    # Open desired TCP and UDP ports
    sudo ufw allow 21114:21119/tcp
    sudo ufw allow 8000/tcp
    sudo ufw allow 21116/udp

    echo "Firewall rules applied."
else
    echo "Failed to enable UFW. No rules were added."
fi