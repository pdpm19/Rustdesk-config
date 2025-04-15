# Server (Linux Distro)

## 1. Install Docker
We're going to install docker using the APT repository
```bash
#!/bin/bash

# ========= Gather OS information =========
echo "Gathering OS information..."
source /etc/os-release
REAL_OS_ID=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
VERSION_CODENAME=${VERSION_CODENAME:-$(lsb_release -cs)}
ARCHITECTURE=$(dpkg --print-architecture)

# Map real OS to Docker repository OS
case "$REAL_OS_ID" in
  pop|linuxmint|elementary|zorin)
    DOCKER_OS_ID="ubuntu"
    ;;
  *)
    DOCKER_OS_ID="$REAL_OS_ID"
    ;;
esac

# Display the OS info
echo "Found the following details from '/etc/os-release':"
echo "  Real OS:            $REAL_OS_ID"
echo "  Repository OS:      $DOCKER_OS_ID"
echo "  Repository Release: $VERSION_CODENAME"
echo "  CPU Architecture:   $ARCHITECTURE"
echo ""

# ========= Update system + dependencies =========
sudo apt-get update && sudo apt-get upgrade -y

# Dependencies
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# ========= Install docker =========
# Keys
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/$DOCKER_OS_ID/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# APT
echo \
  "deb [arch=$ARCHITECTURE signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$DOCKER_OS_ID \
  $VERSION_CODENAME stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install
echo "Installing Docker..."
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Test hello world
echo "Hello World..."
sudo docker run hello-world
```

If all commands run correctly you should see something similar to this.

![docker hello world](pictures/docker_hello_world.png)

Now we can move to the next step.

## 2. Download and Configuration of the Server app
RustDesk needs two executables:
- hbbs - RustDesk ID server (signaling)
    - TPC ports: 21115, 21116, 21118
    - UDP: 21116
- hbbr - RustDesk relay server
    - TPC: 21117, 21119

If needed, the previous ports will need to be open in the firewall
```bash
#!/bin/bash

# ========= Firewall Ports =========
echo "Installing UFW..."
sudo apt-get install -y ufw

# UFW status
echo "UFW status..."
UFW_STATUS=$(sudo ufw status | grep -i "Status: active")

# Define local IP (adjust this!)
LOCAL_IP="192.168.x.x"

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
```

Now we can download the executables
```bash
#!/bin/bash

# ========= Configuration =========
# Set your local IP address here (adjust this!)
LOCAL_IP="192.168.x.x"

# Base directory for RustDesk files
RUSTDESK_DIR="$HOME/docker/rustdesk"
HBBS_DIR="$RUSTDESK_DIR/hbbs"
HBBR_DIR="$RUSTDESK_DIR/hbbr"

# ========= Setup Directories =========
echo "Creating directories for RustDesk server..."
mkdir -p "$HBBS_DIR" "$HBBR_DIR"
cd "$RUSTDESK_DIR" || exit

# ========= Create Docker Compose File =========
echo "Creating Docker Compose file..."

cat <<EOF > docker-compose.yml
version: '3.8'

networks:
  rustdesk-net:
    external: false

services:
  hbbs:
    container_name: hbbs
    image: rustdesk/rustdesk-server:latest
    command: hbbs -r ${LOCAL_IP}:21117 -k _
    volumes:
      - ./hbbs:/root
    ports:
      - 21115:21115
      - 21116:21116
      - 21116:21116/udp
      - 21118:21118
    networks:
      - rustdesk-net
    depends_on:
      - hbbr
    restart: unless-stopped

  hbbr:
    container_name: hbbr
    image: rustdesk/rustdesk-server:latest
    command: hbbr -k _
    volumes:
      - ./hbbr:/root
    ports:
      - 21117:21117
      - 21119:21119
    networks:
      - rustdesk-net
    restart: unless-stopped
EOF

# ========= Launch Containers =========
echo "Starting RustDesk server containers..."
sudo docker compose up -d

# ========= Verify =========
echo "Contents of $RUSTDESK_DIR:"
ls "$RUSTDESK_DIR"

echo "Running Docker containers:"
sudo docker ps
```
![docker ps](pictures/docker_done.png)
And it's all for ther server side
