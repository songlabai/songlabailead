# SongLabAI n8n Lead Generation System
# Dockerfile for Railway deployment

FROM n8nio/n8n:latest

# Set environment variables for Cloud Run
ENV PORT=8080
ENV N8N_HOST=0.0.0.0
ENV N8N_PORT=8080
ENV NODE_ENV=production
ENV N8N_DISABLE_UI=false
ENV N8N_BASIC_AUTH_ACTIVE=false

# Install additional dependencies for lead generation workflows
USER root

# Install curl and other utilities for HTTP requests
RUN apk add --no-cache \
    curl \
    postgresql-client \
    python3 \
    py3-pip \
    py3-virtualenv

# Create and activate virtual environment for Python packages
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python packages in virtual environment
RUN pip install --no-cache-dir \
    requests \
    beautifulsoup4 \
    pandas \
    python-dotenv

# Stay as root and find n8n path
RUN which n8n || find / -name "n8n" -type f 2>/dev/null | head -1

# Create directories for custom workflows and data  
RUN mkdir -p /home/node/.n8n/custom && chown -R node:node /home/node/.n8n

# Copy workflow files (if they exist)
COPY --chown=node:node n8n-workflows/ /home/node/.n8n/workflows/
COPY --chown=node:node email-templates/ /home/node/.n8n/email-templates/

# Switch back to node user but preserve PATH
USER node

# Expose the port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/healthz || exit 1

# Start n8n directly (simplified)
CMD ["n8n", "start"]