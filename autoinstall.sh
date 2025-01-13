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
    while true; do
        read -p "Please enter your Real-Debrid token: " token
        if [[ -z "$token" ]]; then
            echo "Token cannot be empty. Please try again."
        else
            echo "$token"
            break
        fi
    done
}

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Update package list and install Rclone if not installed
log_message "Updating package list and installing Rclone..."
sudo apt update
sudo apt install -y rclone
check_error

# Install unzip if not installed
log_message "Installing unzip..."
sudo apt install -y unzip
check_error

# Check Rclone installation
log_message "Checking Rclone version..."
rclone version
check_error

# Download the latest Zurg release
log_message "Downloading the latest Zurg release..."
ZURG_DIR="$HOME/zurg"
mkdir -p "$ZURG_DIR"
cd "$ZURG_DIR" || { echo "Failed to change directory to $ZURG_DIR"; exit 1; }

ZURG_VERSION="v0.9.3-final"
ZURG_URL="https://github.com/debridmediamanager/zurg-testing/releases/download/$ZURG_VERSION/zurg-$ZURG_VERSION-linux-amd64.zip"
curl -L "$ZURG_URL" -o "zurg-$ZURG_VERSION-linux-amd64.zip"
check_error

# Unzip Zurg
log_message "Unzipping Zurg..."
unzip "zurg-$ZURG_VERSION-linux-amd64.zip"
check_error
rm "zurg-$ZURG_VERSION-linux-amd64.zip"

# Prompt for Real-Debrid token
token=$(prompt_token)

# Create Zurg config.yml file
log_message "Creating config.yml for Zurg..."
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
log_message "Creating Rclone config file..."
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
log_message "Creating mount point for Rclone..."
MOUNT_POINT="/mnt/zurg"
sudo mkdir -p "$MOUNT_POINT"
sudo chown "$USER":"$(id -gn)" "$MOUNT_POINT"
check_error

# Create systemd service for Zurg
log_message "Creating systemd service for Zurg..."
ZURG_SERVICE="/etc/systemd/system/zurg.service"
cat <<EOF | sudo tee "$ZURG_SERVICE" > /dev/null
[Unit]
Description=zurg
After=network-online.target

[Service]
Type=simple
ExecStart=$ZURG_DIR/zurg
WorkingDirectory=$ZURG_DIR
StandardOutput=append:/var/log/zurg.log
StandardError=append:/var/log/zurg.log
Restart=on-abort
RestartSec=1
StartLimitInterval=600s
StartLimitBurst=5

[Install]
WantedBy=multi-user.target
EOF

# Create systemd service for Rclone
log_message "Creating systemd service for Rclone..."
RCLONE_SERVICE="/etc/systemd/system/rclone-zurg.service"
cat <<EOF | sudo tee "$RCLONE_SERVICE" > /dev/null
[Unit]
Description=Rclone mount for Zurg
After=network-online.target
Requires=zurg.service

[Service]
Type=simple
ExecStart=/usr/bin/rclone mount zurg: $MOUNT_POINT --dir-cache-time 30s --allow-other --config $RCLONE_CONFIG_DIR/rclone.conf
Restart=on-abort
RestartSec=1

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to recognize new services
log_message "Reloading systemd..."
sudo systemctl daemon-reload
check_error

# Enable and start services
log_message "Starting services..."
sudo systemctl enable zurg.service
sudo systemctl start zurg.service
check_error

sudo systemctl enable rclone-zurg.service
sudo systemctl start rclone-zurg.service
check_error

# Check the status of services
log_message "Checking the status of Zurg service..."
sudo systemctl status zurg.service

log_message "Checking the status of Rclone service..."
sudo systemctl status rclone-zurg.service

log_message "Setup complete! Services are running."
