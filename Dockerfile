# SongLabAI n8n Lead Generation System
# Dockerfile for Railway deployment

FROM n8nio/n8n:latest

# Set environment variables
ENV N8N_HOST=0.0.0.0
ENV N8N_PORT=5678
ENV NODE_ENV=production

# Install additional dependencies for lead generation workflows
USER root

# Install curl and other utilities for HTTP requests
RUN apk add --no-cache \
    curl \
    postgresql-client \
    python3 \
    py3-pip

# Install Python packages for data processing
RUN pip3 install \
    requests \
    beautifulsoup4 \
    pandas \
    python-dotenv

# Switch back to n8n user
USER node

# Create directories for custom workflows and data
RUN mkdir -p /home/node/.n8n/custom

# Copy workflow files (if they exist)
COPY --chown=node:node n8n-workflows/ /home/node/.n8n/workflows/
COPY --chown=node:node email-templates/ /home/node/.n8n/email-templates/

# Expose the port
EXPOSE 5678

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:5678/healthz || exit 1

# Start n8n
CMD ["n8n", "start"]