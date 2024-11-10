#!/bin/bash

# Function to check for errors
check_error() {
    if [ $? -ne 0 ]; then
        echo "An error occurred. Exiting..."
        exit 1
    fi
}

# Function to prompt for Real-Debrid token
prompt_token() {
    read -p "Please enter your Real-Debrid token: " token
    echo "$token"
}

# Update package list and install Rclone if not installed
echo "Updating package list and installing Rclone..."
sudo apt update
sudo apt install -y rclone
check_error

# Install unzip if not installed
echo "Updating package list and installing Rclone..."
sudo apt install -y unzip
check_error

# Check Rclone installation
echo "Checking Rclone version..."
rclone version
check_error

# Download the latest Zurg release
echo "Downloading the latest Zurg release..."
ZURG_DIR="$HOME/zurg"
mkdir -p "$ZURG_DIR"
cd "$ZURG_DIR"
curl -L "https://github.com/debridmediamanager/zurg-testing/releases/download/v0.9.3-final/zurg-v0.9.3-final-linux-amd64.zip" -o zurg-v0.9.3-final-linux-amd64.zip
check_error

# Unzip Zurg
echo "Unzipping Zurg..."
unzip zurg-v0.9.3-final-linux-amd64.zip
check_error
rm zurg-v0.9.3-final-linux-amd64.zip

# Prompt for Real-Debrid token
token=$(prompt_token)

# Create Zurg config.yml file
echo "Creating config.yml for Zurg..."
cat <<EOF > config.yml
zurg: v1
token: $token
check_for_changes_every_secs: 10
enable_repair: true
auto_delete_rar_torrents: true

directories:
  anime:
    group_order: 10
    group: media
    filters:
      - regex: /\b[a-fA-F0-9]{8}\b/
      - any_file_inside_regex: /\b[a-fA-F0-9]{8}\b/

  shows:
    group_order: 20
    group: media
    filters:
      - has_episodes: true

  movies:
    group_order: 30
    group: media
    only_show_the_biggest_file: true
    filters:
      - regex: /.*/
EOF

# Create Rclone config file
echo "Creating Rclone config file..."
RCLONE_CONFIG_DIR="$HOME/.config/rclone"
mkdir -p "$RCLONE_CONFIG_DIR"
cat <<EOF > "$RCLONE_CONFIG_DIR/rclone.conf"
[zurg]
type = webdav
url = http://localhost:9999/dav
vendor = other
pacer_min_sleep = 0

[zurghttp]
type = http
url = http://localhost:9999/http
no_head = false
no_slash = false
EOF

# Create mount point for Rclone
echo "Creating mount point for Rclone..."
MOUNT_POINT="/mnt/zurg"
sudo mkdir -p "$MOUNT_POINT"
sudo chown "$USER":"$(id -gn)" "$MOUNT_POINT"
check_error

# Create systemd service for Zurg
echo "Creating systemd service for Zurg..."
ZURG_SERVICE="/etc/systemd/system/zurg.service"
cat <<EOF | sudo tee "$ZURG_SERVICE" > /dev/null
[Unit]
Description=zurg
After=network-online.target

[Service]
Type=simple
ExecStart=$ZURG_DIR/zurg
WorkingDirectory=$ZURG_DIR
StandardOutput=file:/var/log/zurg.log
StandardError=file:/var/log/zurg.log
Restart=on-abort
RestartSec=1
StartLimitInterval=600s
StartLimitBurst=5

[Install]
WantedBy=multi-user.target
EOF

# Create systemd service for Rclone
echo "Creating systemd service for Rclone..."
RCLONE_SERVICE="/etc/systemd/system/rclone-zurg.service"
cat <<EOF | sudo tee "$RCLONE_SERVICE" > /dev/null
[Unit]
Description=Rclone mount for Zurg
After=network-online.target
Requires=zurg.service

[Service]
Type=simple
ExecStart=/usr/bin/rclone mount zurg: $MOUNT_POINT --dir-cache-time 30s --allow-other
WorkingDirectory=$RCLONE_CONFIG_DIR
Restart=on-abort
RestartSec=1

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to recognize new services
echo "Reloading systemd..."
sudo systemctl daemon-reload
check_error

# Enable and start services
echo "Starting services..."
sudo systemctl enable zurg.service
sudo systemctl start zurg.service
check_error

sudo systemctl enable rclone-zurg.service
sudo systemctl start rclone-zurg.service
check_error

# Check the status of services
echo "Checking the status of Zurg service..."
sudo systemctl status zurg.service

echo "Checking the status of Rclone service..."
sudo systemctl status rclone-zurg.service

echo "Setup complete! Services are running."
