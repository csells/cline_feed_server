#!/bin/bash

# Simplified Cloud Run deployment for Cline Feed Server
# This version doesn't require a database since we only need web scraping

set -e

REGION="us-central1"
SERVICE_NAME="cline-feed-server"

echo "🚀 Deploying Cline Feed Server to Cloud Run"
echo "Region: $REGION"
echo "Service: $SERVICE_NAME"
echo ""

# Check that we are running from the correct directory
if [ ! -f pubspec.yaml ]; then
    echo "❌ Run this script from the root of your server directory"
    exit 1
fi

# Enable required APIs
echo "📋 Enabling required APIs..."
gcloud services enable run.googleapis.com
gcloud services enable cloudbuild.googleapis.com

# Deploy to Cloud Run
echo "🚀 Deploying to Cloud Run..."
gcloud run deploy $SERVICE_NAME \
  --source=. \
  --region=$REGION \
  --platform=managed \
  --port=8080 \
  --allow-unauthenticated \
  --memory=1Gi \
  --cpu=1 \
  --max-instances=10 \
  --set-env-vars="runmode=production" \
  --set-env-vars="role=serverless"

# Get service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format='value(status.url)')

echo ""
echo "🎉 Deployment completed successfully!"
echo ""
echo "🌐 Your Cline Feed Server is available at:"
echo "   $SERVICE_URL"
echo ""
echo "🔗 ATOM Feed URL:"
echo "   $SERVICE_URL/atom.xml"
echo ""
echo "🔄 Test your feed:"
echo "   curl $SERVICE_URL/atom.xml"