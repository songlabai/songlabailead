#!/bin/bash

echo "🚀 Setting up Google Cloud for SongLabAI Lead Generation System"
echo "==============================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project configuration
PROJECT_ID="songlabai-leadgen"
REGION="us-central1"
DB_INSTANCE="songlabai-db"
DB_NAME="songlabai_leadgen"
DB_USER="songlabai_user"

echo -e "${BLUE}📋 Project Configuration:${NC}"
echo "Project ID: $PROJECT_ID"
echo "Region: $REGION"
echo "Database Instance: $DB_INSTANCE"
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ Google Cloud SDK not found!${NC}"
    echo "Please install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Authenticate user
echo -e "${YELLOW}🔐 Authenticating with Google Cloud...${NC}"
gcloud auth login

# Create project
echo -e "${YELLOW}🏗️  Creating Google Cloud project...${NC}"
gcloud projects create $PROJECT_ID --name="SongLabAI Lead Generation" || echo "Project already exists, continuing..."

# Set project as default
gcloud config set project $PROJECT_ID

# Enable billing (required for some services)
echo -e "${YELLOW}⚠️  Please ensure billing is enabled for your project at:${NC}"
echo "https://console.cloud.google.com/billing/linkedaccount?project=$PROJECT_ID"
read -p "Press Enter after enabling billing to continue..."

# Enable required APIs
echo -e "${YELLOW}🔌 Enabling required APIs...${NC}"
gcloud services enable \
  cloudbuild.googleapis.com \
  run.googleapis.com \
  sqladmin.googleapis.com \
  secretmanager.googleapis.com \
  container.googleapis.com \
  places-backend.googleapis.com \
  maps-backend.googleapis.com \
  geocoding-backend.googleapis.com \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com

echo -e "${GREEN}✅ APIs enabled successfully${NC}"

# Create service account
echo -e "${YELLOW}👤 Creating service account...${NC}"
gcloud iam service-accounts create songlabai-service-account \
  --display-name="SongLabAI Service Account" \
  --description="Service account for SongLabAI lead generation system" || echo "Service account exists, continuing..."

# Grant necessary roles to service account
SERVICE_ACCOUNT_EMAIL="songlabai-service-account@$PROJECT_ID.iam.gserviceaccount.com"

echo -e "${YELLOW}🔑 Granting roles to service account...${NC}"
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
  --role="roles/cloudsql.client"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
  --role="roles/secretmanager.secretAccessor"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
  --role="roles/run.invoker"

# Create and download service account key
echo -e "${YELLOW}🔐 Creating service account key...${NC}"
gcloud iam service-accounts keys create ../config/service-account-key.json \
  --iam-account=$SERVICE_ACCOUNT_EMAIL

echo -e "${GREEN}✅ Service account key saved to config/service-account-key.json${NC}"

# Create Cloud SQL instance
echo -e "${YELLOW}🗄️  Creating Cloud SQL PostgreSQL instance...${NC}"
gcloud sql instances create $DB_INSTANCE \
  --database-version=POSTGRES_15 \
  --tier=db-f1-micro \
  --region=$REGION \
  --storage-type=HDD \
  --storage-size=10GB \
  --no-backup \
  --authorized-networks=0.0.0.0/0 || echo "Database instance exists, continuing..."

# Create database
echo -e "${YELLOW}📊 Creating database...${NC}"
gcloud sql databases create $DB_NAME --instance=$DB_INSTANCE || echo "Database exists, continuing..."

# Generate secure password
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

# Create database user
echo -e "${YELLOW}👤 Creating database user...${NC}"
gcloud sql users create $DB_USER \
  --instance=$DB_INSTANCE \
  --password="$DB_PASSWORD" || echo "User exists, continuing..."

# Get database connection details
CONNECTION_NAME=$(gcloud sql instances describe $DB_INSTANCE --format="value(connectionName)")
DB_IP=$(gcloud sql instances describe $DB_INSTANCE --format="value(ipAddresses[0].ipAddress)")

echo -e "${GREEN}✅ Database created successfully${NC}"
echo "Connection Name: $CONNECTION_NAME"
echo "Database IP: $DB_IP"

# Extract service account details from JSON
echo -e "${YELLOW}📋 Extracting service account details...${NC}"
SERVICE_ACCOUNT_EMAIL_EXTRACTED=$(grep -o '"client_email": "[^"]*' ../config/service-account-key.json | grep -o '[^"]*$')
PRIVATE_KEY_EXTRACTED=$(grep -o '"private_key": "[^"]*' ../config/service-account-key.json | cut -d'"' -f4)

# Create secrets in Secret Manager
echo -e "${YELLOW}🔒 Creating secrets in Secret Manager...${NC}"

# Database URL
DATABASE_URL="postgresql://$DB_USER:$DB_PASSWORD@$DB_IP:5432/$DB_NAME?sslmode=require"
echo -n "$DATABASE_URL" | gcloud secrets create database-url --data-file=- || gcloud secrets versions add database-url --data-file=- <<< "$DATABASE_URL"

# Service account details
echo -n "$SERVICE_ACCOUNT_EMAIL_EXTRACTED" | gcloud secrets create google-service-account-email --data-file=- || gcloud secrets versions add google-service-account-email --data-file=- <<< "$SERVICE_ACCOUNT_EMAIL_EXTRACTED"
echo -n "$PRIVATE_KEY_EXTRACTED" | gcloud secrets create google-private-key --data-file=- || gcloud secrets versions add google-private-key --data-file=- <<< "$PRIVATE_KEY_EXTRACTED"

# Generate n8n encryption key
N8N_KEY=$(openssl rand -hex 16)
echo -n "$N8N_KEY" | gcloud secrets create n8n-encryption-key --data-file=- || gcloud secrets versions add n8n-encryption-key --data-file=- <<< "$N8N_KEY"

echo -e "${GREEN}✅ Base secrets created${NC}"

# Prompt for remaining API keys
echo -e "${BLUE}🔑 Please provide your API keys:${NC}"

echo -e "${YELLOW}Google Maps API Key:${NC}"
echo "1. Go to: https://console.cloud.google.com/apis/credentials?project=$PROJECT_ID"
echo "2. Click 'Create Credentials' > 'API Key'"
echo "3. Copy the key and paste it below:"
read -p "Google Maps API Key: " GOOGLE_MAPS_KEY
echo -n "$GOOGLE_MAPS_KEY" | gcloud secrets create google-maps-api-key --data-file=- || gcloud secrets versions add google-maps-api-key --data-file=- <<< "$GOOGLE_MAPS_KEY"

echo -e "${YELLOW}Calendly API Key (you have this already):${NC}"
read -p "Calendly API Token: " CALENDLY_KEY
echo -n "$CALENDLY_KEY" | gcloud secrets create calendly-api-key --data-file=- || gcloud secrets versions add calendly-api-key --data-file=- <<< "$CALENDLY_KEY"

echo -e "${YELLOW}SMTP Settings:${NC}"
read -p "SMTP Host (e.g., smtp-relay.brevo.com): " SMTP_HOST
read -p "SMTP User/Email: " SMTP_USER  
read -p "SMTP Password/API Key: " SMTP_PASS
echo -n "$SMTP_HOST" | gcloud secrets create smtp-host --data-file=- || gcloud secrets versions add smtp-host --data-file=- <<< "$SMTP_HOST"
echo -n "$SMTP_USER" | gcloud secrets create smtp-user --data-file=- || gcloud secrets versions add smtp-user --data-file=- <<< "$SMTP_USER"
echo -n "$SMTP_PASS" | gcloud secrets create smtp-password --data-file=- || gcloud secrets versions add smtp-password --data-file=- <<< "$SMTP_PASS"

# Optional APIs
echo -e "${BLUE}Optional API Keys (press Enter to skip):${NC}"
read -p "Proxycurl API Key (optional): " PROXYCURL_KEY
if [ ! -z "$PROXYCURL_KEY" ]; then
    echo -n "$PROXYCURL_KEY" | gcloud secrets create proxycurl-api-key --data-file=- || gcloud secrets versions add proxycurl-api-key --data-file=- <<< "$PROXYCURL_KEY"
fi

read -p "RapidAPI Key (optional): " RAPIDAPI_KEY
if [ ! -z "$RAPIDAPI_KEY" ]; then
    echo -n "$RAPIDAPI_KEY" | gcloud secrets create rapidapi-key --data-file=- || gcloud secrets versions add rapidapi-key --data-file=- <<< "$RAPIDAPI_KEY"
fi

read -p "Slack Webhook URL (optional): " SLACK_WEBHOOK
if [ ! -z "$SLACK_WEBHOOK" ]; then
    echo -n "$SLACK_WEBHOOK" | gcloud secrets create slack-webhook-url --data-file=- || gcloud secrets versions add slack-webhook-url --data-file=- <<< "$SLACK_WEBHOOK"
fi

# Create deployment configuration file
echo -e "${YELLOW}📝 Creating deployment configuration...${NC}"
cat > ../config/deployment-config.sh << EOF
#!/bin/bash
# Deployment configuration for SongLabAI Lead Generation System

export PROJECT_ID="$PROJECT_ID"
export REGION="$REGION"
export DB_INSTANCE="$DB_INSTANCE"
export DB_CONNECTION_NAME="$CONNECTION_NAME"
export SERVICE_ACCOUNT_EMAIL="$SERVICE_ACCOUNT_EMAIL_EXTRACTED"

# Service URLs (will be updated after deployment)
export SERVICE_NAME="songlabai-n8n"
export SERVICE_URL=""  # Will be populated after deployment
EOF

echo -e "${GREEN}✅ Google Cloud setup complete!${NC}"
echo ""
echo -e "${BLUE}📋 Summary:${NC}"
echo "✅ Project created: $PROJECT_ID"
echo "✅ APIs enabled"
echo "✅ Service account created: $SERVICE_ACCOUNT_EMAIL_EXTRACTED"
echo "✅ PostgreSQL database created: $DB_INSTANCE"
echo "✅ Secrets stored in Secret Manager"
echo "✅ Configuration saved"
echo ""
echo -e "${YELLOW}🚀 Next steps:${NC}"
echo "1. Review your Google Maps API key restrictions"
echo "2. Run './deploy.sh' to deploy the application"
echo "3. Run './setup-database.sh' to initialize the database"
echo ""
echo -e "${BLUE}💰 Cost estimate with your \$300 credit:${NC}"
echo "- Cloud Run: ~\$5-15/month"
echo "- Cloud SQL: ~\$7/month (db-f1-micro)"
echo "- Other services: <\$3/month"
echo "- Total: ~\$15-25/month (12+ months with \$300 credit)"
echo ""
echo -e "${GREEN}Setup complete! 🎉${NC}"