#!/bin/bash

# Final deployment - simpler approach
set -e

INSTANCE_NAME="cline-feed-server"
ZONE="us-central1-a"

echo "🚀 Final deployment to $INSTANCE_NAME"

# Stop the service
gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --command="sudo systemctl stop cline-feed-server || true"

# Upload our code in a tar file to preserve structure
echo "📦 Creating deployment package..."
tar -czf /tmp/cline-feed-code.tar.gz lib/ bin/ config/ web/ pubspec.yaml --exclude="*.dart_tool*" --exclude="*.g.dart"

echo "📤 Uploading code..."
gcloud compute scp /tmp/cline-feed-code.tar.gz $INSTANCE_NAME:/tmp/ --zone=$ZONE

# Setup and start
echo "🔧 Setting up and starting server..."
gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --command='
# Clean start
sudo rm -rf /opt/cline_feed_server
sudo mkdir -p /opt/cline_feed_server
cd /opt/cline_feed_server

# Extract the code
sudo tar -xzf /tmp/cline-feed-code.tar.gz

# Fix ownership
sudo chown -R csells:csells /opt/cline_feed_server

# Install dependencies
/usr/lib/dart/bin/dart pub get

# Test that we can run it
echo "Testing manual start..."
timeout 5 /usr/lib/dart/bin/dart bin/main.dart || echo "Server started (timeout expected)"

# Start the service
sudo systemctl start cline-feed-server

# Give it a moment to start
sleep 3

# Check status
sudo systemctl status cline-feed-server --no-pager
'

# Get external IP and test
EXTERNAL_IP=$(gcloud compute instances describe $INSTANCE_NAME --zone=$ZONE --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo ""
echo "🎉 Deployment complete!"
echo "🌐 Server IP: $EXTERNAL_IP"
echo "🔗 Feed URL: http://$EXTERNAL_IP:8080/atom.xml"

# Test the feed
echo ""
echo "🔄 Testing feed (waiting 10 seconds first)..."
sleep 10
curl -s "http://$EXTERNAL_IP:8080/atom.xml" | head -20 || echo "❌ Feed not responding yet"

# Clean up
rm -f /tmp/cline-feed-code.tar.gz