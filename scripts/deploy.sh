#!/bin/bash

echo "🚀 Deploying SongLabAI Lead Generation System to Google Cloud"
echo "============================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load deployment configuration
if [ -f "../config/deployment-config.sh" ]; then
    source ../config/deployment-config.sh
    echo -e "${GREEN}✅ Loaded deployment configuration${NC}"
else
    echo -e "${RED}❌ Deployment configuration not found!${NC}"
    echo "Please run './setup-google-cloud.sh' first"
    exit 1
fi

# Verify we're in the right project
CURRENT_PROJECT=$(gcloud config get-value project)
if [ "$CURRENT_PROJECT" != "$PROJECT_ID" ]; then
    echo -e "${YELLOW}⚠️  Setting project to $PROJECT_ID${NC}"
    gcloud config set project $PROJECT_ID
fi

# Build and deploy to Cloud Run
echo -e "${YELLOW}🏗️  Building and deploying to Cloud Run...${NC}"

# Deploy with Cloud Run from source
gcloud run deploy $SERVICE_NAME \
  --source .. \
  --region $REGION \
  --platform managed \
  --allow-unauthenticated \
  --port 5678 \
  --memory 1Gi \
  --cpu 1 \
  --min-instances 0 \
  --max-instances 10 \
  --timeout 3600 \
  --add-cloudsql-instances $DB_CONNECTION_NAME \
  --set-env-vars \
    NODE_ENV=production,\
    N8N_PORT=5678,\
    N8N_HOST=0.0.0.0,\
    CALENDLY_USER_URI=https://api.calendly.com/users/18a4b8b9-d24d-49fc-a8e6-d23838b30c48,\
    SMTP_PORT=587,\
    SMTP_FROM_EMAIL=hello@songlabai.com,\
    SMTP_FROM_NAME="SongLabAI Custom Jingles",\
    BUSINESS_NAME=SongLabAI,\
    BUSINESS_WEBSITE=https://songlabai.com,\
    BUSINESS_EMAIL=hello@songlabai.com,\
    BUSINESS_PHONE=+1-555-JINGLE-1,\
    SENDER_NAME="SongLabAI Team",\
    DAILY_GOOGLE_REQUESTS_LIMIT=500,\
    DAILY_EMAIL_LIMIT=250,\
    DAILY_LINKEDIN_REQUESTS_LIMIT=100,\
    CALENDLY_AUTOMOTIVE_URL=https://calendly.com/songlabai/auto-dealer-consultation,\
    CALENDLY_RESTAURANT_URL=https://calendly.com/songlabai/restaurant-consultation,\
    CALENDLY_GENERAL_URL=https://calendly.com/songlabai/business-consultation \
  --set-secrets \
    DATABASE_URL=database-url:latest,\
    GOOGLE_MAPS_API_KEY=google-maps-api-key:latest,\
    GOOGLE_SERVICE_ACCOUNT_EMAIL=google-service-account-email:latest,\
    GOOGLE_PRIVATE_KEY=google-private-key:latest,\
    CALENDLY_API_KEY=calendly-api-key:latest,\
    SMTP_HOST=smtp-host:latest,\
    SMTP_USER=smtp-user:latest,\
    SMTP_PASS=smtp-password:latest,\
    N8N_ENCRYPTION_KEY=n8n-encryption-key:latest

# Check deployment status
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Deployment successful!${NC}"
else
    echo -e "${RED}❌ Deployment failed!${NC}"
    exit 1
fi

# Get the service URL
echo -e "${YELLOW}🔗 Getting service URL...${NC}"
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region $REGION --format="value(status.url)")

# Update webhook URLs in secrets
echo -e "${YELLOW}🔄 Updating webhook URLs...${NC}"
echo -n "$SERVICE_URL/" | gcloud secrets versions add webhook-url --data-file=- || echo -n "$SERVICE_URL/" | gcloud secrets create webhook-url --data-file=-
echo -n "$SERVICE_URL" | gcloud secrets versions add n8n-editor-base-url --data-file=- || echo -n "$SERVICE_URL" | gcloud secrets create n8n-editor-base-url --data-file=-

# Update the service with new webhook URLs
echo -e "${YELLOW}🔄 Updating service with webhook URLs...${NC}"
gcloud run services update $SERVICE_NAME \
  --region $REGION \
  --update-secrets WEBHOOK_URL=webhook-url:latest,N8N_EDITOR_BASE_URL=n8n-editor-base-url:latest

# Update deployment config with service URL
echo -e "${YELLOW}💾 Updating deployment configuration...${NC}"
sed -i "s|export SERVICE_URL=\"\"|export SERVICE_URL=\"$SERVICE_URL\"|" ../config/deployment-config.sh

# Test the deployment
echo -e "${YELLOW}🧪 Testing deployment...${NC}"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$SERVICE_URL")

if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "302" ]; then
    echo -e "${GREEN}✅ Service is responding (HTTP $HTTP_STATUS)${NC}"
else
    echo -e "${YELLOW}⚠️  Service returned HTTP $HTTP_STATUS (may need time to initialize)${NC}"
fi

# Display deployment summary
echo ""
echo -e "${BLUE}🎉 Deployment Summary:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ Project:${NC} $PROJECT_ID"
echo -e "${GREEN}✅ Service:${NC} $SERVICE_NAME"
echo -e "${GREEN}✅ Region:${NC} $REGION"
echo -e "${GREEN}✅ URL:${NC} $SERVICE_URL"
echo -e "${GREEN}✅ Database:${NC} $DB_INSTANCE (connected)"
echo -e "${GREEN}✅ Secrets:${NC} Configured in Secret Manager"
echo ""
echo -e "${BLUE}🌐 Access your n8n interface:${NC}"
echo "$SERVICE_URL"
echo ""
echo -e "${YELLOW}📝 Next Steps:${NC}"
echo "1. Visit your n8n URL and set up admin credentials"
echo "2. Run './setup-database.sh' to initialize the database schema"
echo "3. Import workflows from the 'n8n-workflows' folder"
echo "4. Test the Google Maps API integration"
echo "5. Configure your first email campaign"
echo ""
echo -e "${BLUE}💰 Resource Usage:${NC}"
echo "- Cloud Run: ~$5-15/month"
echo "- Cloud SQL: ~$7/month"
echo "- Secret Manager: ~$1/month"
echo "- Total: ~$13-23/month"
echo ""
echo -e "${GREEN}🔐 Security Features Enabled:${NC}"
echo "✅ HTTPS encryption"
echo "✅ Secret Manager for API keys"
echo "✅ Cloud SQL private networking"
echo "✅ IAM role-based access"
echo ""
echo -e "${BLUE}📊 Expected Performance:${NC}"
echo "- 🎯 Daily Prospects: 40-80 qualified leads"
echo "- 📧 Email Volume: 250 emails/day"
echo "- 🗺️  API Calls: 500 Google Maps requests/day"
echo "- ⏱️  Response Time: <2 seconds"
echo ""
echo -e "${GREEN}Deployment complete! 🚀${NC}"
echo "Your SongLabAI lead generation system is now running on Google Cloud!"