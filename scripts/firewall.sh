echo "=== Installing the Firewall ==="
# Install the firewall
sudo apt-get install ufw

# Adds acess via SSH
ufw allow proto tcp from YOURIP to any port 22

# Adds the ports
ufw allow 21114:21119/tcp
ufw allow 8000/tcp
ufw allow 21116/udp
sudo ufw enable