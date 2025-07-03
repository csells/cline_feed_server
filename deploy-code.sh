#!/bin/bash

# Cline Feed Server - Code Deployment Script
# This script uploads your code to the Compute Engine instance and starts the server

set -e

# Configuration
INSTANCE_NAME="cline-feed-server"
ZONE="us-central1-a"
REMOTE_DIR="/opt/cline_feed_server"

echo "📦 Deploying code to Cline Feed Server"
echo "Instance: $INSTANCE_NAME"
echo "Zone: $ZONE"
echo ""

# Check if instance exists
if ! gcloud compute instances describe $INSTANCE_NAME --zone=$ZONE >/dev/null 2>&1; then
    echo "❌ Error: Instance $INSTANCE_NAME not found in zone $ZONE"
    echo "💡 Run ./deploy-compute-engine.sh first to create the instance"
    exit 1
fi

# Check if instance is running
INSTANCE_STATUS=$(gcloud compute instances describe $INSTANCE_NAME --zone=$ZONE --format='get(status)')
if [ "$INSTANCE_STATUS" != "RUNNING" ]; then
    echo "⚠️  Instance is not running (status: $INSTANCE_STATUS)"
    echo "🔄 Starting instance..."
    gcloud compute instances start $INSTANCE_NAME --zone=$ZONE
    echo "⏳ Waiting for instance to start..."
    sleep 30
fi

echo "📂 Step 1: Preparing code for upload..."

# Create a temporary directory with only the files we need
TEMP_DIR="/tmp/cline_feed_deploy"
rm -rf $TEMP_DIR
mkdir -p $TEMP_DIR

# Copy necessary files
cp -r lib/ $TEMP_DIR/
cp -r bin/ $TEMP_DIR/
cp -r config/ $TEMP_DIR/
cp -r web/ $TEMP_DIR/ 2>/dev/null || echo "No web directory found, skipping..."
cp pubspec.yaml $TEMP_DIR/
cp pubspec.lock $TEMP_DIR/ 2>/dev/null || echo "No pubspec.lock found, will generate..."

# Exclude generated files and other unnecessary items
find $TEMP_DIR -name "*.g.dart" -delete 2>/dev/null || true
find $TEMP_DIR -name ".dart_tool" -type d -exec rm -rf {} + 2>/dev/null || true

echo "📤 Step 2: Uploading code to instance..."
gcloud compute scp --recurse $TEMP_DIR/* $INSTANCE_NAME:$REMOTE_DIR --zone=$ZONE

echo "🔧 Step 3: Installing dependencies and starting server..."
gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --command="
    set -e
    cd $REMOTE_DIR
    
    echo '📦 Installing Dart dependencies...'
    /usr/lib/dart/bin/dart pub get
    
    echo '🔧 Stopping any existing service...'
    sudo systemctl stop cline-feed-server 2>/dev/null || true
    
    echo '⚡ Starting Cline Feed Server...'
    sudo systemctl enable cline-feed-server
    sudo systemctl start cline-feed-server
    
    echo '✅ Service started successfully!'
    
    # Show service status
    sudo systemctl status cline-feed-server --no-pager
"

# Get external IP
EXTERNAL_IP=$(gcloud compute instances describe $INSTANCE_NAME \
    --zone=$ZONE \
    --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo ""
echo "🎉 Code deployment completed successfully!"
echo ""
echo "🌐 Your Cline Feed Server is now running at:"
echo "   http://$EXTERNAL_IP:8080/atom.xml"
echo ""
echo "📊 Monitor the service:"
echo "   gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --command='sudo systemctl status cline-feed-server'"
echo ""
echo "📝 View logs:"
echo "   gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --command='sudo journalctl -u cline-feed-server -f'"
echo ""
echo "🔄 Test the feed:"
echo "   curl http://$EXTERNAL_IP:8080/atom.xml"

# Clean up
rm -rf $TEMP_DIR

echo ""
echo "✅ All done! Your feed server is live!"