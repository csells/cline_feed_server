#!/bin/bash

# Cline Feed Server - Compute Engine Deployment Script
# This script deploys your server to a GCP Compute Engine instance

set -e

# Configuration
PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project)}"
INSTANCE_NAME="cline-feed-server"
ZONE="us-central1-a"
MACHINE_TYPE="e2-micro"  # Free tier eligible
IMAGE_FAMILY="ubuntu-2204-lts"
IMAGE_PROJECT="ubuntu-os-cloud"

echo "🚀 Deploying Cline Feed Server to Compute Engine"
echo "Project: $PROJECT_ID"
echo "Instance: $INSTANCE_NAME"
echo "Zone: $ZONE"
echo ""

# Check if gcloud is configured
if [ -z "$PROJECT_ID" ]; then
    echo "❌ Error: No GCP project set. Run: gcloud config set project YOUR_PROJECT_ID"
    exit 1
fi

echo "📋 Step 1: Enabling required APIs..."
gcloud services enable compute.googleapis.com

echo "🔥 Step 2: Creating firewall rule for HTTP traffic..."
if ! gcloud compute firewall-rules describe allow-cline-feed-http >/dev/null 2>&1; then
    gcloud compute firewall-rules create allow-cline-feed-http \
        --allow tcp:8080 \
        --source-ranges 0.0.0.0/0 \
        --target-tags http-server \
        --description "Allow HTTP traffic to Cline Feed Server"
    echo "✅ Firewall rule created"
else
    echo "✅ Firewall rule already exists"
fi

echo "💾 Step 3: Creating startup script..."
cat > /tmp/startup-script.sh << 'EOF'
#!/bin/bash
set -e

# Log everything
exec > >(tee -a /var/log/startup-script.log)
exec 2>&1

echo "🔧 Starting Cline Feed Server setup..."

# Update system
apt-get update
apt-get install -y curl git unzip wget gnupg2

# Install Dart SDK
echo "📦 Installing Dart SDK..."
wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/dart.gpg
echo 'deb [signed-by=/usr/share/keyrings/dart.gpg arch=amd64] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main' | tee /etc/apt/sources.list.d/dart_stable.list

apt-get update
apt-get install -y dart

# Add Dart to PATH
export PATH="$PATH:/usr/lib/dart/bin"
echo 'export PATH="$PATH:/usr/lib/dart/bin"' >> /etc/environment

# Create app user and directory
useradd -m -s /bin/bash clineserver || true
mkdir -p /opt/cline_feed_server
chown clineserver:clineserver /opt/cline_feed_server

echo "✅ System setup complete"
echo "📁 Ready for code deployment at /opt/cline_feed_server"
echo "🔧 To deploy code, run the deploy script from your local machine"

# Create systemd service template
cat > /etc/systemd/system/cline-feed-server.service << 'SYSTEMD_EOF'
[Unit]
Description=Cline Feed Server
After=network.target

[Service]
Type=simple
User=clineserver
WorkingDirectory=/opt/cline_feed_server
Environment=PATH=/usr/lib/dart/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=/usr/lib/dart/bin/dart bin/main.dart
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SYSTEMD_EOF

systemctl daemon-reload
echo "🎯 Service template created. Will start after code deployment."
EOF

echo "🖥️  Step 4: Creating Compute Engine instance..."
if gcloud compute instances describe $INSTANCE_NAME --zone=$ZONE >/dev/null 2>&1; then
    echo "⚠️  Instance $INSTANCE_NAME already exists. Updating startup script..."
    gcloud compute instances add-metadata $INSTANCE_NAME \
        --zone=$ZONE \
        --metadata-from-file startup-script=/tmp/startup-script.sh
else
    gcloud compute instances create $INSTANCE_NAME \
        --zone=$ZONE \
        --machine-type=$MACHINE_TYPE \
        --image-family=$IMAGE_FAMILY \
        --image-project=$IMAGE_PROJECT \
        --tags=http-server \
        --metadata-from-file startup-script=/tmp/startup-script.sh \
        --scopes=https://www.googleapis.com/auth/cloud-platform
    echo "✅ Instance created"
fi

# Wait for instance to be ready
echo "⏳ Waiting for instance to start up..."
sleep 30

# Get external IP
EXTERNAL_IP=$(gcloud compute instances describe $INSTANCE_NAME \
    --zone=$ZONE \
    --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo ""
echo "🎉 Compute Engine instance created successfully!"
echo ""
echo "📋 Instance Details:"
echo "   Name: $INSTANCE_NAME"
echo "   Zone: $ZONE"
echo "   Type: $MACHINE_TYPE"
echo "   External IP: $EXTERNAL_IP"
echo ""
echo "🔄 Next Steps:"
echo "1. Wait 2-3 minutes for the startup script to complete"
echo "2. Run: ./deploy-code.sh"
echo "3. Your feed will be available at: http://$EXTERNAL_IP:8080/atom.xml"
echo ""
echo "📊 Monitor startup progress:"
echo "   gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --command='sudo tail -f /var/log/startup-script.log'"
echo ""
echo "🔌 SSH into instance:"
echo "   gcloud compute ssh $INSTANCE_NAME --zone=$ZONE"

# Clean up
rm /tmp/startup-script.sh

echo "✅ Deployment script completed!"