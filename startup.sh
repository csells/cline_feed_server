#!/bin/bash

# Startup script for Compute Engine deployment
# This script installs Dart, clones the repo, and starts the server

set -e

# Update system
apt-get update
apt-get install -y curl git unzip

# Install Dart SDK
wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/dart.gpg
echo 'deb [signed-by=/usr/share/keyrings/dart.gpg arch=amd64] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main' | tee /etc/apt/sources.list.d/dart_stable.list

apt-get update
apt-get install -y dart

# Add Dart to PATH
export PATH="$PATH:/usr/lib/dart/bin"
echo 'export PATH="$PATH:/usr/lib/dart/bin"' >> /etc/environment

# Create app directory
mkdir -p /opt/cline_feed_server
cd /opt/cline_feed_server

# Clone or copy your code (you'll need to upload it first)
# For now, create a placeholder - you'll need to upload your code
echo "# Upload your cline_feed_server code to this directory" > README.txt

# Install dependencies (when code is present)
# dart pub get

# Create systemd service
cat > /etc/systemd/system/cline-feed-server.service << EOF
[Unit]
Description=Cline Feed Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/cline_feed_server
Environment=PATH=/usr/lib/dart/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=/usr/lib/dart/bin/dart bin/main.dart
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable the service (will start when code is uploaded)
systemctl enable cline-feed-server

echo "Setup complete. Upload your code to /opt/cline_feed_server and run: systemctl start cline-feed-server"