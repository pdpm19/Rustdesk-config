echo "== Downloading Docker ==="
# Add Docker's official GPG key:
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/raspbian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/raspbian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install docker packages
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# hello-world example
sudo docker run hello-world


echo "=== Creating RustDesk folders =="
# First we create the home directory for rustdesk
mkdir -p $HOME/rustdesk/hbbs
mkdir -p $HOME/rustdesk/hbbr
cd $HOME/rustdesk

# Then we create the docker compose file (change the LOCAL_IP variable to your current network IP 192.168.x.x, before running this script)
LOCAL_IP="192.168.x.x"
cat <<EOF > docker-compose.yml
networks:
  rustdesk-net:
    external: false

services:
  hbbs:
    container_name: hbbs
    ports:
      - 21115:21115
      - 21116:21116
      - 21116:21116/udp
      - 21118:21118
    image: rustdesk/rustdesk-server:latest
    command: hbbs -r $LOCAL_IP:21117 -k _
    volumes:
      - ./hbbs:/root
    networks:
      - rustdesk-net
    depends_on:
      - hbbr
    restart: unless-stopped

  hbbr:
    container_name: hbbr
    ports:
      - 21117:21117
      - 21119:21119
    image: rustdesk/rustdesk-server:latest
    command: hbbr -k _
    volumes:
      - ./hbbr:/root
    networks:
      - rustdesk-net
    restart: unless-stopped
EOF

# Start the containers
echo "=== Starting the containers ==="
sudo docker compose up -d

echo "=== Verifying if all done correct ==="
ls $HOME/rustdesk
sudo docker ps