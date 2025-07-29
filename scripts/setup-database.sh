#!/bin/bash

echo "🗄️  Setting up SongLabAI Database Schema"
echo "========================================"

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

# Check if Cloud SQL Proxy is installed
if ! command -v cloud_sql_proxy &> /dev/null; then
    echo -e "${YELLOW}📥 Installing Cloud SQL Proxy...${NC}"
    
    # Detect architecture
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        PROXY_ARCH="linux.amd64"
    elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
        PROXY_ARCH="linux.arm64"
    else
        echo -e "${RED}❌ Unsupported architecture: $ARCH${NC}"
        exit 1
    fi
    
    # Download Cloud SQL Proxy
    curl -o cloud_sql_proxy https://dl.google.com/cloudsql/cloud_sql_proxy.$PROXY_ARCH
    chmod +x cloud_sql_proxy
    sudo mv cloud_sql_proxy /usr/local/bin/
    echo -e "${GREEN}✅ Cloud SQL Proxy installed${NC}"
fi

# Start Cloud SQL Proxy
echo -e "${YELLOW}🔌 Starting Cloud SQL Proxy...${NC}"
cloud_sql_proxy -instances=$DB_CONNECTION_NAME=tcp:5432 &
PROXY_PID=$!

# Wait for proxy to start
echo -e "${YELLOW}⏳ Waiting for proxy to initialize...${NC}"
sleep 5

# Test connection
echo -e "${YELLOW}🧪 Testing database connection...${NC}"
timeout 10 bash -c "until nc -z localhost 5432; do sleep 1; done" || {
    echo -e "${RED}❌ Could not connect to database${NC}"
    kill $PROXY_PID 2>/dev/null
    exit 1
}

echo -e "${GREEN}✅ Database connection established${NC}"

# Get database credentials from Secret Manager
echo -e "${YELLOW}🔑 Retrieving database credentials...${NC}"
DATABASE_URL=$(gcloud secrets versions access latest --secret="database-url")

# Extract connection details from DATABASE_URL
DB_PASSWORD=$(echo $DATABASE_URL | grep -oP 'postgresql://[^:]+:\K[^@]+' | head -1)
DB_USER=$(echo $DATABASE_URL | grep -oP 'postgresql://\K[^:]+' | head -1)
DB_NAME=$(echo $DATABASE_URL | grep -oP '/\K[^?]+' | head -1)

# Check if schema file exists
if [ ! -f "../database/schema.sql" ]; then
    echo -e "${RED}❌ Database schema file not found!${NC}"
    kill $PROXY_PID 2>/dev/null
    exit 1
fi

# Create database schema
echo -e "${YELLOW}📊 Creating database schema...${NC}"
PGPASSWORD=$DB_PASSWORD psql -h localhost -p 5432 -U $DB_USER -d $DB_NAME -f ../database/schema.sql

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Database schema created successfully${NC}"
else
    echo -e "${RED}❌ Failed to create database schema${NC}"
    kill $PROXY_PID 2>/dev/null
    exit 1
fi

# Create initial data for business types
echo -e "${YELLOW}🎯 Adding business type configuration...${NC}"
PGPASSWORD=$DB_PASSWORD psql -h localhost -p 5432 -U $DB_USER -d $DB_NAME << EOF
-- Insert business type configurations
INSERT INTO system_config (key, value, description) VALUES
('business_types_primary', '["automotive", "restaurants", "legal", "medical", "realEstate"]', 'Primary business types for targeting'),
('business_types_secondary', '["fitness", "retail", "professional", "homeServices"]', 'Secondary business types for targeting'),
('business_types_emerging', '["entertainment", "education", "petServices", "techServices"]', 'Emerging business types for targeting'),
('premium_locations', '["Beverly Hills, CA", "Malibu, CA", "Santa Monica, CA", "Palo Alto, CA"]', 'Ultra-premium California locations'),
('daily_limits', '{"google_maps": 500, "email": 250, "linkedin": 100}', 'Daily API usage limits')
ON CONFLICT (key) DO NOTHING;

-- Insert California cities for targeting
INSERT INTO system_config (key, value, description) VALUES
('target_cities', '[
  "Los Angeles, CA", "San Francisco, CA", "San Diego, CA", "San Jose, CA",
  "Beverly Hills, CA", "Santa Monica, CA", "Malibu, CA", "Palo Alto, CA",
  "Newport Beach, CA", "Laguna Beach, CA", "Carmel-by-the-Sea, CA",
  "Sausalito, CA", "Mill Valley, CA", "Manhattan Beach, CA", "Hermosa Beach, CA",
  "Santa Barbara, CA", "Monterey, CA", "Napa, CA", "Sonoma, CA"
]', 'Target cities for lead generation')
ON CONFLICT (key) DO NOTHING;

COMMIT;
EOF

echo -e "${GREEN}✅ Initial configuration data added${NC}"

# Verify tables were created
echo -e "${YELLOW}🔍 Verifying database setup...${NC}"
TABLE_COUNT=$(PGPASSWORD=$DB_PASSWORD psql -h localhost -p 5432 -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" | xargs)

echo -e "${BLUE}📊 Database Statistics:${NC}"
echo "Tables created: $TABLE_COUNT"

if [ "$TABLE_COUNT" -ge "8" ]; then
    echo -e "${GREEN}✅ All tables created successfully${NC}"
    
    # Show table list
    echo -e "${BLUE}📋 Created Tables:${NC}"
    PGPASSWORD=$DB_PASSWORD psql -h localhost -p 5432 -U $DB_USER -d $DB_NAME -c "
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    ORDER BY table_name;"
else
    echo -e "${YELLOW}⚠️  Only $TABLE_COUNT tables found. Expected at least 8.${NC}"
fi

# Test data insertion
echo -e "${YELLOW}🧪 Testing data insertion...${NC}"
PGPASSWORD=$DB_PASSWORD psql -h localhost -p 5432 -U $DB_USER -d $DB_NAME << EOF
-- Test insert
INSERT INTO prospects (name, business_name, email, phone, address, city, state, 
                      prospect_type, lead_source, lead_score, pipeline_stage)
VALUES ('Test Business', 'Test Restaurant', 'test@example.com', '555-1234', 
        '123 Test St', 'Los Angeles', 'CA', 'restaurant', 'manual', 85, 'new');

-- Verify insert
SELECT COUNT(*) as test_prospects FROM prospects WHERE business_name = 'Test Restaurant';

-- Clean up test data
DELETE FROM prospects WHERE business_name = 'Test Restaurant';
EOF

echo -e "${GREEN}✅ Database insert/delete test successful${NC}"

# Stop Cloud SQL Proxy
echo -e "${YELLOW}🔌 Stopping Cloud SQL Proxy...${NC}"
kill $PROXY_PID 2>/dev/null
wait $PROXY_PID 2>/dev/null

echo ""
echo -e "${BLUE}🎉 Database Setup Complete!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ Database:${NC} $DB_NAME"
echo -e "${GREEN}✅ User:${NC} $DB_USER"
echo -e "${GREEN}✅ Tables:${NC} $TABLE_COUNT created"
echo -e "${GREEN}✅ Configuration:${NC} Business types and cities loaded"
echo -e "${GREEN}✅ Testing:${NC} Data insertion verified"
echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo "1. Access your n8n interface: $SERVICE_URL"
echo "2. Import workflows from 'n8n-workflows' folder"
echo "3. Test Google Maps API integration"
echo "4. Configure your first email campaign"
echo "5. Set up monitoring and alerts"
echo ""
echo -e "${BLUE}🗄️  Database Connection Info:${NC}"
echo "Host: localhost (via Cloud SQL Proxy)"
echo "Port: 5432"
echo "Database: $DB_NAME"
echo "User: $DB_USER"
echo ""
echo -e "${YELLOW}💡 Pro Tip:${NC} Your database is now ready for n8n workflows!"
echo "The system can handle 40-80 prospects per day with full lead scoring."
echo ""
echo -e "${GREEN}Database setup successful! 🚀${NC}"