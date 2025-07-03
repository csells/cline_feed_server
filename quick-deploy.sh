#!/bin/bash

# Quick deployment script that handles setup and deployment in one go

set -e

INSTANCE_NAME="cline-feed-server"
ZONE="us-central1-a"

echo "🚀 Quick deployment to $INSTANCE_NAME"

# Upload code first to home directory, then move it
echo "📤 Uploading code..."
gcloud compute scp --recurse lib/ bin/ config/ web/ pubspec.yaml $INSTANCE_NAME:~ --zone=$ZONE

# Connect and setup everything
echo "🔧 Setting up server..."
gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --command='
# Wait for startup script basics
while [ ! -f /etc/apt/sources.list.d/dart_stable.list ]; do
    echo "Waiting for Dart repository to be added..."
    sleep 10
done

# Ensure system is updated and Dart is installed
sudo apt-get update
sudo apt-get install -y dart

# Create proper directory structure
sudo mkdir -p /opt/cline_feed_server
sudo chown $USER:$USER /opt/cline_feed_server

# Move code to proper location
cp -r lib/ bin/ config/ pubspec.yaml /opt/cline_feed_server/
[ -d web/ ] && cp -r web/ /opt/cline_feed_server/ || echo "No web directory"

# Change to app directory
cd /opt/cline_feed_server

# Install dependencies
/usr/lib/dart/bin/dart pub get

# Create systemd service
sudo tee /etc/systemd/system/cline-feed-server.service > /dev/null << EOF
[Unit]
Description=Cline Feed Server
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=/opt/cline_feed_server
Environment=PATH=/usr/lib/dart/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=/usr/lib/dart/bin/dart bin/main.dart
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable cline-feed-server
sudo systemctl start cline-feed-server

# Show status
sudo systemctl status cline-feed-server --no-pager
'

# Get external IP
EXTERNAL_IP=$(gcloud compute instances describe $INSTANCE_NAME \
    --zone=$ZONE \
    --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo ""
echo "🎉 Deployment completed!"
echo ""
echo "🌐 Your Cline Feed Server is running at:"
echo "   http://$EXTERNAL_IP:8080/atom.xml"
echo ""
echo "🔄 Test it:"
echo "   curl http://$EXTERNAL_IP:8080/atom.xml"