# Deploy Cline Feed Server to Google Cloud

⚠️ **Important**: Cloud Run's serverless nature means instances scale to zero and restart frequently, which **breaks in-memory caching**. You need persistent storage for caching.

## Deployment Options

### Option 1: Cloud Run + Redis (Recommended)
Best for: Serverless, cost-effective, with persistent caching

### Option 2: Compute Engine 
Best for: Always-on instance with reliable in-memory caching

---

## Option 1: Cloud Run + Redis

### Prerequisites

1. **Google Cloud CLI installed**:
   ```bash
   curl https://sdk.cloud.google.com | bash
   exec -l $SHELL
   gcloud init
   ```

2. **Set up your project**:
   ```bash
   export PROJECT_ID="your-project-id"
   gcloud config set project $PROJECT_ID
   gcloud auth login
   gcloud services enable run.googleapis.com
   gcloud services enable redis.googleapis.com
   ```

3. **Create Redis instance**:
   ```bash
   gcloud redis instances create cline-feed-cache \
     --size=1 \
     --region=us-central1 \
     --redis-version=redis_6_x \
     --tier=basic
   ```

4. **Get Redis connection info**:
   ```bash
   gcloud redis instances describe cline-feed-cache --region=us-central1
   # Note the host IP for environment variables
   ```

### Deploy with Redis

```bash
# Deploy with Redis connection
gcloud run deploy cline-feed-server \
  --source=. \
  --region=us-central1 \
  --platform=managed \
  --port=8080 \
  --allow-unauthenticated \
  --memory=1Gi \
  --cpu=1 \
  --max-instances=10 \
  --set-env-vars="REDIS_HOST=10.x.x.x,REDIS_PORT=6379" \
  --vpc-connector=your-vpc-connector
```

---

## Option 2: Compute Engine (Always-On)

For reliable in-memory caching without code changes:

```bash
# Create a small VM instance
gcloud compute instances create cline-feed-vm \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --image-family=ubuntu-2004-lts \
  --image-project=ubuntu-os-cloud \
  --tags=http-server \
  --metadata-from-file startup-script=startup.sh

# Create firewall rule
gcloud compute firewall-rules create allow-cline-feed \
  --allow tcp:8080 \
  --source-ranges 0.0.0.0/0 \
  --target-tags http-server
```

## Your Feed URL

After deployment, you'll get a URL like:
```
https://cline-feed-server-xxxxx-uc.a.run.app/atom.xml
```

## Custom Domain (Optional)

To use a custom domain:

1. **Map domain**:
   ```bash
   gcloud run domain-mappings create \
     --service=cline-feed-server \
     --domain=feeds.yourdomain.com \
     --region=us-central1
   ```

2. **Update DNS** with the provided DNS records

## Environment Variables

You can set environment variables during deployment:
```bash
gcloud run deploy cline-feed-server \
  --source=. \
  --region=us-central1 \
  --set-env-vars="CACHE_DURATION=3600"
```

## Monitoring

View logs:
```bash
gcloud run services logs tail cline-feed-server --region=us-central1
```

## Cost Estimation

- **Free tier**: Up to 2 million requests/month
- **Beyond free tier**: ~$0.40 per million requests
- **Memory/CPU**: ~$0.0000024 per vCPU-second, ~$0.0000025 per GiB-second

For a feed server, costs should be minimal!