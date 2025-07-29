-- SongLabAI n8n Lead Generation System
-- PostgreSQL Database Schema

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Set timezone to Pacific (California time)
SET timezone = 'America/Los_Angeles';

-- =============================================
-- PROSPECTS TABLE - Main prospect data
-- =============================================
CREATE TABLE prospects (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    
    -- Basic Information
    name VARCHAR(255) NOT NULL,
    business_name VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(50),
    website VARCHAR(255),
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(2) DEFAULT 'CA',
    zip_code VARCHAR(10),
    
    -- Business Classification
    prospect_type VARCHAR(50) NOT NULL, -- 'automotive', 'restaurant', 'legal', 'medical', 'real_estate', 'general_business'
    industry_category VARCHAR(100),
    business_size VARCHAR(20), -- 'small', 'medium', 'large'
    
    -- Lead Information
    lead_source VARCHAR(50) NOT NULL, -- 'google_maps', 'linkedin_alternative', 'referral', 'manual'
    lead_score INTEGER DEFAULT 0 CHECK (lead_score >= 0 AND lead_score <= 100),
    budget_estimate VARCHAR(20) DEFAULT 'medium', -- 'low', 'medium', 'medium-high', 'high'
    priority_level VARCHAR(20) DEFAULT 'normal', -- 'low', 'normal', 'high', 'urgent'
    
    -- Personalization Data
    jingle_needs TEXT[], -- Array of needs like 'radio_ads', 'phone_hold', 'video_content', 'tv_commercials'
    personalized_angle TEXT,
    pain_points TEXT[],
    business_highlights TEXT[],
    
    -- Contact Status
    contacted BOOLEAN DEFAULT FALSE,
    contact_method VARCHAR(50), -- 'email', 'phone', 'linkedin', 'social_media'
    last_contact_date TIMESTAMP WITH TIME ZONE,
    contact_attempts INTEGER DEFAULT 0,
    
    -- Meeting & Pipeline
    meeting_booked BOOLEAN DEFAULT FALSE,
    meeting_date TIMESTAMP WITH TIME ZONE,
    meeting_type VARCHAR(50), -- 'consultation', 'demo', 'follow_up'
    pipeline_stage VARCHAR(50) DEFAULT 'new', -- 'new', 'contacted', 'engaged', 'meeting_scheduled', 'proposal_sent', 'negotiation', 'closed_won', 'closed_lost', 'nurture'
    
    -- Geographic & Targeting
    in_california BOOLEAN DEFAULT TRUE,
    is_premium_area BOOLEAN DEFAULT FALSE,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    
    -- Business Intelligence
    google_rating DECIMAL(2, 1) CHECK (google_rating >= 0 AND google_rating <= 5),
    google_review_count INTEGER DEFAULT 0,
    price_level INTEGER CHECK (price_level >= 0 AND price_level <= 4), -- Google Maps price level
    business_hours JSONB,
    website_quality_score INTEGER CHECK (website_quality_score >= 0 AND website_quality_score <= 100),
    
    -- Tracking & Analytics
    utm_source VARCHAR(100),
    utm_medium VARCHAR(100),
    utm_campaign VARCHAR(100),
    conversion_probability DECIMAL(5, 2) DEFAULT 0.00,
    estimated_revenue DECIMAL(10, 2),
    
    -- System Fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) DEFAULT 'system',
    tags TEXT[],
    notes TEXT,
    
    -- Soft Delete
    deleted_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE
);

-- Indexes for prospects table
CREATE INDEX idx_prospects_email ON prospects(email) WHERE email IS NOT NULL;
CREATE INDEX idx_prospects_business_name ON prospects USING GIN(business_name gin_trgm_ops);
CREATE INDEX idx_prospects_prospect_type ON prospects(prospect_type);
CREATE INDEX idx_prospects_lead_source ON prospects(lead_source);
CREATE INDEX idx_prospects_pipeline_stage ON prospects(pipeline_stage);
CREATE INDEX idx_prospects_lead_score ON prospects(lead_score DESC);
CREATE INDEX idx_prospects_contacted ON prospects(contacted, last_contact_date);
CREATE INDEX idx_prospects_meeting_booked ON prospects(meeting_booked, meeting_date);
CREATE INDEX idx_prospects_created_at ON prospects(created_at DESC);
CREATE INDEX idx_prospects_location ON prospects(city, state, is_premium_area);
CREATE INDEX idx_prospects_active ON prospects(is_active, deleted_at) WHERE deleted_at IS NULL;

-- =============================================
-- GOOGLE_MAPS_DATA TABLE - Google Maps specific data
-- =============================================
CREATE TABLE google_maps_data (
    id SERIAL PRIMARY KEY,
    prospect_id INTEGER REFERENCES prospects(id) ON DELETE CASCADE,
    
    -- Google Maps Specific Fields
    place_id VARCHAR(255) UNIQUE NOT NULL,
    google_url TEXT,
    google_maps_url TEXT,
    photo_urls TEXT[],
    categories TEXT[],
    
    -- Business Details from Google
    formatted_address TEXT,
    formatted_phone_number VARCHAR(50),
    international_phone_number VARCHAR(50),
    opening_hours JSONB,
    popular_times JSONB,
    
    -- Reviews and Ratings
    rating DECIMAL(2, 1),
    user_ratings_total INTEGER,
    reviews JSONB,
    
    -- Additional Google Data
    types TEXT[],
    vicinity TEXT,
    plus_code VARCHAR(100),
    utc_offset INTEGER,
    
    -- Data Quality
    data_freshness TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_google_maps_place_id ON google_maps_data(place_id);
CREATE INDEX idx_google_maps_prospect_id ON google_maps_data(prospect_id);
CREATE INDEX idx_google_maps_rating ON google_maps_data(rating DESC, user_ratings_total DESC);

-- =============================================
-- LINKEDIN_DATA TABLE - LinkedIn alternative data
-- =============================================
CREATE TABLE linkedin_data (
    id SERIAL PRIMARY KEY,
    prospect_id INTEGER REFERENCES prospects(id) ON DELETE CASCADE,
    
    -- LinkedIn Profile Data
    linkedin_url TEXT,
    profile_id VARCHAR(255),
    
    -- Personal Information
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    headline VARCHAR(255),
    summary TEXT,
    location VARCHAR(255),
    
    -- Professional Information
    current_company VARCHAR(255),
    current_position VARCHAR(255),
    industry VARCHAR(100),
    experience_years INTEGER,
    connections_count INTEGER,
    
    -- Company Information
    company_size VARCHAR(50),
    company_industry VARCHAR(100),
    company_website VARCHAR(255),
    
    -- Data Source
    data_source VARCHAR(50), -- 'proxycurl', 'rapidapi', 'manual'
    api_response JSONB,
    
    -- Quality Control
    profile_verified BOOLEAN DEFAULT FALSE,
    data_confidence_score INTEGER CHECK (data_confidence_score >= 0 AND data_confidence_score <= 100),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_linkedin_prospect_id ON linkedin_data(prospect_id);
CREATE INDEX idx_linkedin_url ON linkedin_data(linkedin_url);
CREATE INDEX idx_linkedin_company ON linkedin_data(current_company);

-- =============================================
-- EMAIL_CAMPAIGNS TABLE - Email tracking
-- =============================================
CREATE TABLE email_campaigns (
    id SERIAL PRIMARY KEY,
    prospect_id INTEGER REFERENCES prospects(id) ON DELETE CASCADE,
    
    -- Email Details
    email_type VARCHAR(50) NOT NULL, -- 'initial_outreach', 'follow_up_1', 'follow_up_2', 'follow_up_3', 'meeting_confirmation', 'proposal', 'thank_you'
    subject_line TEXT NOT NULL,
    email_body TEXT,
    template_used VARCHAR(100),
    
    -- Personalization
    personalization_tokens JSONB, -- Store the tokens used for personalization
    ab_test_variant VARCHAR(50),
    
    -- Email Metadata
    from_email VARCHAR(255),
    from_name VARCHAR(255),
    to_email VARCHAR(255) NOT NULL,
    cc_emails TEXT[],
    bcc_emails TEXT[],
    
    -- Tracking
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    delivered_at TIMESTAMP WITH TIME ZONE,
    opened_at TIMESTAMP WITH TIME ZONE,
    clicked_at TIMESTAMP WITH TIME ZONE,
    replied_at TIMESTAMP WITH TIME ZONE,
    bounced_at TIMESTAMP WITH TIME ZONE,
    
    -- Engagement Metrics
    open_count INTEGER DEFAULT 0,
    click_count INTEGER DEFAULT 0,
    links_clicked TEXT[],
    
    -- Status
    delivery_status VARCHAR(50) DEFAULT 'sent', -- 'sent', 'delivered', 'opened', 'clicked', 'replied', 'bounced', 'failed'
    
    -- SMTP Information
    smtp_host VARCHAR(255),
    message_id VARCHAR(255),
    
    -- Response Tracking
    response_received BOOLEAN DEFAULT FALSE,
    response_content TEXT,
    response_sentiment VARCHAR(20), -- 'positive', 'neutral', 'negative'
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_email_campaigns_prospect_id ON email_campaigns(prospect_id);
CREATE INDEX idx_email_campaigns_email_type ON email_campaigns(email_type);
CREATE INDEX idx_email_campaigns_sent_at ON email_campaigns(sent_at DESC);
CREATE INDEX idx_email_campaigns_delivery_status ON email_campaigns(delivery_status);
CREATE INDEX idx_email_campaigns_opened ON email_campaigns(opened_at) WHERE opened_at IS NOT NULL;
CREATE INDEX idx_email_campaigns_clicked ON email_campaigns(clicked_at) WHERE clicked_at IS NOT NULL;

-- =============================================
-- CALENDLY_EVENTS TABLE - Meeting bookings
-- =============================================
CREATE TABLE calendly_events (
    id SERIAL PRIMARY KEY,
    prospect_id INTEGER REFERENCES prospects(id) ON DELETE CASCADE,
    
    -- Calendly Event Data
    calendly_event_id VARCHAR(255) UNIQUE NOT NULL,
    calendly_event_uri TEXT,
    event_type VARCHAR(100),
    event_name VARCHAR(255),
    
    -- Event Details
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_minutes INTEGER,
    timezone VARCHAR(100),
    location TEXT,
    meeting_type VARCHAR(50), -- 'consultation', 'demo', 'follow_up'
    
    -- Attendee Information
    attendee_name VARCHAR(255),
    attendee_email VARCHAR(255),
    attendee_phone VARCHAR(50),
    attendee_notes TEXT,
    
    -- Event Status
    event_status VARCHAR(50) DEFAULT 'scheduled', -- 'scheduled', 'rescheduled', 'canceled', 'completed', 'no_show'
    cancellation_reason TEXT,
    reschedule_count INTEGER DEFAULT 0,
    
    -- Meeting Outcome
    meeting_outcome VARCHAR(50), -- 'proposal_scheduled', 'not_interested', 'needs_follow_up', 'closed_won', 'closed_lost'
    next_steps TEXT,
    proposal_value DECIMAL(10, 2),
    
    -- Tracking
    booking_source VARCHAR(50), -- 'email_link', 'website', 'direct'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_calendly_events_prospect_id ON calendly_events(prospect_id);
CREATE INDEX idx_calendly_events_calendly_id ON calendly_events(calendly_event_id);
CREATE INDEX idx_calendly_events_start_time ON calendly_events(start_time);
CREATE INDEX idx_calendly_events_status ON calendly_events(event_status);

-- =============================================
-- ANALYTICS_DAILY TABLE - Daily metrics
-- =============================================
CREATE TABLE analytics_daily (
    id SERIAL PRIMARY KEY,
    date DATE NOT NULL UNIQUE,
    
    -- Lead Generation Metrics
    prospects_added INTEGER DEFAULT 0,
    google_maps_prospects INTEGER DEFAULT 0,
    linkedin_prospects INTEGER DEFAULT 0,
    
    -- Email Metrics
    emails_sent INTEGER DEFAULT 0,
    emails_delivered INTEGER DEFAULT 0,
    emails_opened INTEGER DEFAULT 0,
    emails_clicked INTEGER DEFAULT 0,
    emails_replied INTEGER DEFAULT 0,
    emails_bounced INTEGER DEFAULT 0,
    
    -- Meeting Metrics
    meetings_booked INTEGER DEFAULT 0,
    meetings_completed INTEGER DEFAULT 0,
    meetings_canceled INTEGER DEFAULT 0,
    meetings_no_show INTEGER DEFAULT 0,
    
    -- Conversion Metrics
    leads_to_contacted DECIMAL(5, 2) DEFAULT 0.00,
    emails_to_meetings DECIMAL(5, 2) DEFAULT 0.00,
    meetings_to_proposals DECIMAL(5, 2) DEFAULT 0.00,
    proposals_to_closed DECIMAL(5, 2) DEFAULT 0.00,
    
    -- Revenue Metrics
    proposals_sent DECIMAL(10, 2) DEFAULT 0.00,
    revenue_won DECIMAL(10, 2) DEFAULT 0.00,
    average_deal_size DECIMAL(10, 2) DEFAULT 0.00,
    
    -- API Usage
    google_api_calls INTEGER DEFAULT 0,
    linkedin_api_calls INTEGER DEFAULT 0,
    calendly_api_calls INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_analytics_daily_date ON analytics_daily(date DESC);

-- =============================================
-- WORKFLOW_LOGS TABLE - n8n workflow execution logs
-- =============================================
CREATE TABLE workflow_logs (
    id SERIAL PRIMARY KEY,
    
    -- Workflow Information
    workflow_name VARCHAR(255) NOT NULL,
    workflow_id VARCHAR(255),
    execution_id VARCHAR(255),
    
    -- Execution Details
    status VARCHAR(50) NOT NULL, -- 'success', 'error', 'warning', 'running'
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE,
    duration_seconds INTEGER,
    
    -- Processing Metrics
    records_processed INTEGER DEFAULT 0,
    records_success INTEGER DEFAULT 0,
    records_failed INTEGER DEFAULT 0,
    
    -- Error Information
    error_message TEXT,
    error_stack TEXT,
    
    -- Context Data
    context_data JSONB,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_workflow_logs_workflow_name ON workflow_logs(workflow_name);
CREATE INDEX idx_workflow_logs_status ON workflow_logs(status);
CREATE INDEX idx_workflow_logs_start_time ON workflow_logs(start_time DESC);

-- =============================================
-- TRIGGERS FOR AUTOMATIC TIMESTAMPS
-- =============================================

-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add triggers for updated_at columns
CREATE TRIGGER update_prospects_updated_at BEFORE UPDATE ON prospects FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_linkedin_data_updated_at BEFORE UPDATE ON linkedin_data FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_calendly_events_updated_at BEFORE UPDATE ON calendly_events FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- VIEWS FOR COMMON QUERIES
-- =============================================

-- Active prospects with latest contact information
CREATE VIEW active_prospects_view AS
SELECT 
    p.*,
    gmd.rating as google_rating,
    gmd.user_ratings_total as google_reviews,
    ld.current_position as contact_position,
    ld.headline as contact_headline,
    ce.start_time as next_meeting,
    (SELECT COUNT(*) FROM email_campaigns ec WHERE ec.prospect_id = p.id) as email_count,
    (SELECT MAX(ec.sent_at) FROM email_campaigns ec WHERE ec.prospect_id = p.id) as last_email_sent
FROM prospects p
LEFT JOIN google_maps_data gmd ON p.id = gmd.prospect_id
LEFT JOIN linkedin_data ld ON p.id = ld.prospect_id
LEFT JOIN calendly_events ce ON p.id = ce.prospect_id AND ce.event_status = 'scheduled'
WHERE p.is_active = TRUE AND p.deleted_at IS NULL;

-- Email performance summary
CREATE VIEW email_performance_view AS
SELECT 
    email_type,
    COUNT(*) as total_sent,
    COUNT(CASE WHEN delivered_at IS NOT NULL THEN 1 END) as delivered,
    COUNT(CASE WHEN opened_at IS NOT NULL THEN 1 END) as opened,
    COUNT(CASE WHEN clicked_at IS NOT NULL THEN 1 END) as clicked,
    COUNT(CASE WHEN replied_at IS NOT NULL THEN 1 END) as replied,
    ROUND(COUNT(CASE WHEN opened_at IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2) as open_rate,
    ROUND(COUNT(CASE WHEN clicked_at IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2) as click_rate,
    ROUND(COUNT(CASE WHEN replied_at IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2) as reply_rate
FROM email_campaigns
WHERE sent_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY email_type;

-- Pipeline summary view
CREATE VIEW pipeline_summary_view AS
SELECT 
    pipeline_stage,
    COUNT(*) as count,
    AVG(lead_score) as avg_lead_score,
    SUM(estimated_revenue) as total_estimated_revenue,
    COUNT(CASE WHEN contacted = TRUE THEN 1 END) as contacted_count,
    COUNT(CASE WHEN meeting_booked = TRUE THEN 1 END) as meeting_booked_count
FROM prospects
WHERE is_active = TRUE AND deleted_at IS NULL
GROUP BY pipeline_stage
ORDER BY 
    CASE pipeline_stage
        WHEN 'new' THEN 1
        WHEN 'contacted' THEN 2
        WHEN 'engaged' THEN 3
        WHEN 'meeting_scheduled' THEN 4
        WHEN 'proposal_sent' THEN 5
        WHEN 'negotiation' THEN 6
        WHEN 'closed_won' THEN 7
        WHEN 'closed_lost' THEN 8
        WHEN 'nurture' THEN 9
        ELSE 10
    END;

-- =============================================
-- INITIAL DATA SETUP
-- =============================================

-- Insert initial analytics record for today
INSERT INTO analytics_daily (date) VALUES (CURRENT_DATE) ON CONFLICT (date) DO NOTHING;

-- Create admin user configuration (optional)
CREATE TABLE IF NOT EXISTS system_config (
    key VARCHAR(100) PRIMARY KEY,
    value TEXT,
    description TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO system_config (key, value, description) VALUES
('system_version', '1.0.0', 'SongLabAI Lead Generation System Version'),
('daily_prospect_limit', '50', 'Maximum prospects to add per day'),
('daily_email_limit', '250', 'Maximum emails to send per day'),
('lead_score_threshold', '45', 'Minimum lead score for outreach'),
('follow_up_intervals', '3,7,14', 'Follow-up intervals in days'),
('system_timezone', 'America/Los_Angeles', 'System timezone')
ON CONFLICT (key) DO NOTHING;

-- Grant necessary permissions (adjust as needed for your deployment)
-- These would typically be handled by your deployment process
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO n8n_user;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO n8n_user;