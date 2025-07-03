# 🚀 Deploy Cline Feed Server to Google Compute Engine

Complete deployment guide for running your Cline Feed Server on a dedicated Compute Engine instance with reliable in-memory caching.

## 🎯 Why Compute Engine?

- ✅ **In-memory caching works perfectly** (no cold starts)
- ✅ **Always-on instance** (predictable performance)
- ✅ **Free tier eligible** (e2-micro instance)
- ✅ **No code changes required**
- ✅ **Simple architecture**

## 📋 Prerequisites

1. **Google Cloud Account** with billing enabled
2. **Google Cloud CLI** installed and configured
3. **Active GCP Project**

### Install Google Cloud CLI (if needed)
```bash
# macOS
brew install google-cloud-sdk

# Or download from: https://cloud.google.com/sdk/docs/install
```

### Configure your project
```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

## 🚀 Quick Deployment (2 commands!)

### Step 1: Create the instance
```bash
chmod +x deploy-compute-engine.sh
./deploy-compute-engine.sh
```

### Step 2: Deploy your code
```bash
chmod +x deploy-code.sh
./deploy-code.sh
```

**That's it!** Your feed server will be running at `http://YOUR_IP:8080/atom.xml`

---

## 📖 Detailed Step-by-Step Guide

### 1. Create Compute Engine Instance

The `deploy-compute-engine.sh` script will:
- ✅ Enable Compute Engine API
- ✅ Create firewall rule for HTTP traffic
- ✅ Create an e2-micro instance (free tier)
- ✅ Install Dart SDK
- ✅ Set up systemd service
- ✅ Configure user and directories

```bash
./deploy-compute-engine.sh
```

**Expected output:**
```
🚀 Deploying Cline Feed Server to Compute Engine
Project: your-project-id
Instance: cline-feed-server
Zone: us-central1-a

📋 Step 1: Enabling required APIs...
✅ Firewall rule created
🖥️  Step 4: Creating Compute Engine instance...
✅ Instance created

🎉 Compute Engine instance created successfully!

📋 Instance Details:
   Name: cline-feed-server
   Zone: us-central1-a
   Type: e2-micro
   External IP: 34.123.45.67
```

### 2. Deploy Your Code

The `deploy-code.sh` script will:
- ✅ Upload your source code
- ✅ Install Dart dependencies
- ✅ Start the systemd service
- ✅ Verify the server is running

```bash
./deploy-code.sh
```

**Expected output:**
```
📦 Deploying code to Cline Feed Server
📤 Step 2: Uploading code to instance...
🔧 Step 3: Installing dependencies and starting server...
📦 Installing Dart dependencies...
⚡ Starting Cline Feed Server...
✅ Service started successfully!

🎉 Code deployment completed successfully!

🌐 Your Cline Feed Server is now running at:
   http://34.123.45.67:8080/atom.xml
```

---

## 🔧 Management Commands

### Monitor Service Status
```bash
gcloud compute ssh cline-feed-server --zone=us-central1-a --command='sudo systemctl status cline-feed-server'
```

### View Live Logs
```bash
gcloud compute ssh cline-feed-server --zone=us-central1-a --command='sudo journalctl -u cline-feed-server -f'
```

### Restart Service
```bash
gcloud compute ssh cline-feed-server --zone=us-central1-a --command='sudo systemctl restart cline-feed-server'
```

### SSH into Instance
```bash
gcloud compute ssh cline-feed-server --zone=us-central1-a
```

### Test Your Feed
```bash
curl http://YOUR_EXTERNAL_IP:8080/atom.xml
```

---

## 💰 Cost Estimation

### Free Tier Benefits
- **e2-micro instance**: 744 hours/month free (always-on!)
- **1 GB outbound traffic/month**: Free
- **30 GB standard persistent disk**: Free

### Beyond Free Tier
- **e2-micro**: ~$5.50/month (if you exceed 744 hours)
- **Outbound traffic**: $0.12/GB after first 1GB
- **Static IP** (optional): $1.46/month

**Expected monthly cost**: $0 (free tier) or ~$5-7 (beyond free tier)

---

## 🛠️ Troubleshooting

### Service Won't Start
```bash
# Check logs
gcloud compute ssh cline-feed-server --zone=us-central1-a --command='sudo journalctl -u cline-feed-server --no-pager'

# Check Dart installation
gcloud compute ssh cline-feed-server --zone=us-central1-a --command='/usr/lib/dart/bin/dart --version'
```

### Can't Access Feed
```bash
# Check firewall
gcloud compute firewall-rules list --filter="name=allow-cline-feed-http"

# Check if service is listening
gcloud compute ssh cline-feed-server --zone=us-central1-a --command='sudo netstat -tlnp | grep 8080'
```

### Update Code
```bash
# Just run the deploy script again
./deploy-code.sh
```

---

## 🔒 Security Notes

- The server runs on port 8080 (not 80/443)
- Firewall rule allows access from anywhere (0.0.0.0/0)
- Consider adding SSL/HTTPS for production use
- Instance has external IP by default

---

## 🎉 What You Get

✅ **Reliable Feed Server**: Always-on instance with working in-memory cache  
✅ **Public ATOM Feed**: Available at `http://YOUR_IP:8080/atom.xml`  
✅ **Automatic Restarts**: systemd manages the service  
✅ **Easy Updates**: Re-run `./deploy-code.sh` to deploy changes  
✅ **Cost Effective**: Free tier eligible or ~$5/month  

Your Cline blog feed is now live and ready to be added to any RSS reader! 🎊