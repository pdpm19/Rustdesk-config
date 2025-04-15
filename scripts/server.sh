#!/bin/bash

# Set your local IP address here (adjust this!)
# This should be the IP from the Server machine (run: ip a)
LOCAL_IP="192.168.x.x"

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

#!/bin/bash

# ========= Configuration =========
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