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

# Install Python packages in virtual environment
RUN /opt/venv/bin/pip install --no-cache-dir \
    requests \
    beautifulsoup4 \
    pandas \
    python-dotenv

# Preserve original PATH with n8n, add venv to end
ENV PATH="/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/venv/bin"

# Verify n8n is accessible
RUN which n8n && n8n --version

# Create directories for custom workflows and data  
RUN mkdir -p /home/node/.n8n/custom && chown -R node:node /home/node/.n8n

# Copy workflow files (if they exist)
COPY --chown=node:node n8n-workflows/ /home/node/.n8n/workflows/
COPY --chown=node:node email-templates/ /home/node/.n8n/email-templates/

# Switch back to node user and ensure PATH is preserved
USER node

# Set PATH at user level to ensure it persists in Cloud Run
ENV PATH="/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/venv/bin"

# Expose the port
EXPOSE 8080

# Health check using full path
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/healthz || exit 1

# Use ENTRYPOINT instead of CMD to ensure proper execution
ENTRYPOINT ["/usr/local/bin/n8n"]
CMD ["start"]