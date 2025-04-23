#!/bin/bash
# Deployment script for Family Recipe AI Service to DigitalOcean
# This script automates the process of deploying the AI service to a DigitalOcean Droplet

set -e  # Exit immediately if a command exits with a non-zero status

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables - modify these as needed
DOCKER_IMAGE_NAME="family-recipe-ai"
DOCKER_IMAGE_TAG=$(date +"%Y%m%d-%H%M%S")
DOCKER_REGISTRY="registry.digitalocean.com/family-recipe-ai"  # Replace with your registry
SSH_KEY_PATH="$HOME/.ssh/id_rsa"
DROPLET_NAME="family-recipe-ai"
DROPLET_SIZE="s-1vcpu-1gb"  # Smallest size suitable for this application
DROPLET_REGION="nyc1"        # Change to your preferred region
DROPLET_SSH_USER="root"      # Default for DO droplets
ENV_FILE=".env.production"    # Path to your production env file
FIREWALL_NAME="family-recipe-ai-fw"
TZ="America/Los_Angeles"     # Timezone for the server

# Log function for better output
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# Check for required tools
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check for Docker
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed. Please install Docker before proceeding."
        exit 1
    fi
    
    # Check for Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose is not installed. Please install Docker Compose before proceeding."
        exit 1
    fi
    
    # Check for doctl (DigitalOcean CLI)
    if ! command -v doctl &> /dev/null; then
        error "doctl is not installed. Please install the DigitalOcean CLI before proceeding."
        error "Visit: https://docs.digitalocean.com/reference/doctl/how-to/install/"
        exit 1
    fi
    
    # Check doctl auth status
    if ! doctl account get &> /dev/null; then
        error "doctl not authenticated. Please run 'doctl auth init' first."
        exit 1
    fi
    
    # Check for SSH key
    if [ ! -f "$SSH_KEY_PATH" ]; then
        error "SSH key not found at $SSH_KEY_PATH. Please specify the correct path."
        exit 1
    fi
    
    # Check for environment file
    if [ ! -f "$ENV_FILE" ]; then
        error "Environment file not found at $ENV_FILE. Please create it first."
        exit 1
    fi
    
    # Check if API_KEY is set in environment file
    if ! grep -q "API_KEY=" "$ENV_FILE" || grep -q "API_KEY=$" "$ENV_FILE" || grep -q "API_KEY=#" "$ENV_FILE"; then
        error "API_KEY is not properly set in $ENV_FILE. Please set a secure API key."
        exit 1
    fi
    
    success "All prerequisites met!"
}

# Build and push Docker image
build_and_push_image() {
    log "Building Docker image: $DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG"
    docker build -t "$DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG" .
    docker tag "$DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG" "$DOCKER_REGISTRY/$DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG"
    docker tag "$DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG" "$DOCKER_REGISTRY/$DOCKER_IMAGE_NAME:latest"
    
    log "Logging in to DigitalOcean container registry..."
    doctl registry login
    
    log "Pushing Docker image to registry..."
    docker push "$DOCKER_REGISTRY/$DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG"
    docker push "$DOCKER_REGISTRY/$DOCKER_IMAGE_NAME:latest"
    
    success "Docker image built and pushed successfully!"
}

# Create or update DigitalOcean Droplet
setup_droplet() {
    log "Checking if Droplet already exists..."
    if doctl compute droplet get "$DROPLET_NAME" &> /dev/null; then
        warning "Droplet '$DROPLET_NAME' already exists. Updating configuration..."
    else
        log "Creating new Droplet: $DROPLET_NAME"
        doctl compute droplet create "$DROPLET_NAME" \
            --image docker-20-04 \
            --size "$DROPLET_SIZE" \
            --region "$DROPLET_REGION" \
            --ssh-keys "$(doctl compute ssh-key list --format ID --no-header)" \
            --wait
        
        success "Droplet created successfully!"
        sleep 15  # Give some time for the droplet to initialize
    fi
    
    # Get Droplet IP
    DROPLET_IP=$(doctl compute droplet get "$DROPLET_NAME" --format PublicIPv4 --no-header)
    log "Droplet IP: $DROPLET_IP"
    
    # Wait for SSH to be available
    log "Waiting for SSH to become available..."
    for i in {1..30}; do
        if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i "$SSH_KEY_PATH" "$DROPLET_SSH_USER@$DROPLET_IP" "echo SSH connection established" &> /dev/null; then
            success "SSH connection established!"
            break
        fi
        
        if [ $i -eq 30 ]; then
            error "Failed to establish SSH connection after multiple attempts."
            exit 1
        fi
        
        echo -n "."
        sleep 5
    done
}

# Configure server environment
configure_server() {
    log "Configuring server environment..."
    
    # Create remote directory structure
    ssh -i "$SSH_KEY_PATH" "$DROPLET_SSH_USER@$DROPLET_IP" "mkdir -p ~/family-recipe-ai/data ~/family-recipe-ai/logs"
    
    # Copy environment file
    log "Copying environment file..."
    scp -i "$SSH_KEY_PATH" "$ENV_FILE" "$DROPLET_SSH_USER@$DROPLET_IP:~/family-recipe-ai/.env"
    
    # Create docker-compose file on the server
    log "Creating docker-compose.yml on server..."
    ssh -i "$SSH_KEY_PATH" "$DROPLET_SSH_USER@$DROPLET_IP" "cat > ~/family-recipe-ai/docker-compose.yml" << EOF
version: '3.8'

services:
  ai-service:
    image: $DOCKER_REGISTRY/$DOCKER_IMAGE_NAME:latest
    container_name: family-recipe-ai
    restart: unless-stopped
    ports:
      - "8000:8000"
    environment:
      - TZ=$TZ
    env_file:
      - .env
    volumes:
      - ./logs:/app/logs
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
EOF
    
    # Install and configure ufw firewall
    log "Configuring firewall..."
    ssh -i "$SSH_KEY_PATH" "$DROPLET_SSH_USER@$DROPLET_IP" << 'ENDSSH'
    # Install dependencies
    apt-get update
    apt-get install -y ufw curl

    # Configure firewall
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow 8000/tcp
    echo "y" | ufw enable
    
    # Update timezone
    ln -fs /usr/share/zoneinfo/$TZ /etc/localtime
    
    # Install Docker if not already installed
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
    fi
    
    # Install Docker Compose if not already installed
    if ! command -v docker-compose &> /dev/null; then
        curl -L "https://github.com/docker/compose/releases/download/v2.17.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi
    
    # Log in to Docker registry
    mkdir -p ~/.docker
ENDSSH

    # Docker registry login on server
    log "Logging into Docker registry from server..."
    doctl registry login
    doctl registry docker-config > docker-config.json
    scp -i "$SSH_KEY_PATH" docker-config.json "$DROPLET_SSH_USER@$DROPLET_IP:~/.docker/config.json"
    rm docker-config.json
    
    success "Server configuration completed!"
}

# Deploy the application
deploy_application() {
    log "Deploying application to Droplet..."
    
    # Pull and start the containers
    ssh -i "$SSH_KEY_PATH" "$DROPLET_SSH_USER@$DROPLET_IP" << ENDSSH
    cd ~/family-recipe-ai
    docker-compose pull
    docker-compose down || true
    docker-compose up -d
ENDSSH
    
    success "Application deployed successfully!"
}

# Verify deployment
verify_deployment() {
    log "Verifying deployment..."
    
    # Check if container is running
    log "Checking container status..."
    CONTAINER_RUNNING=$(ssh -i "$SSH_KEY_PATH" "$DROPLET_SSH_USER@$DROPLET_IP" "docker ps | grep family-recipe-ai | wc -l")
    
    if [ "$CONTAINER_RUNNING" -eq 0 ]; then
        error "Container is not running! Checking logs..."
        ssh -i "$SSH_KEY_PATH" "$DROPLET_SSH_USER@$DROPLET_IP" "docker-compose -f ~/family-recipe-ai/docker-compose.yml logs"
        exit 1
    fi
    
    # Check health endpoint
    log "Checking health endpoint..."
    for i in {1..12}; do
        HEALTH_CHECK=$(ssh -i "$SSH_KEY_PATH" "$DROPLET_SSH_USER@$DROPLET_IP" \
                      "curl -s -o /dev/null -w '%{http_code}' http://localhost:8000/health")
        
        if [ "$HEALTH_CHECK" -eq 200 ]; then
            success "Health check passed! Application is running correctly."
            break
        fi
        
        if [ $i -eq 12 ]; then
            error "Health check failed after multiple attempts."
            error "Please check the logs: ssh -i $SSH_KEY_PATH $DROPLET_SSH_USER@$DROPLET_IP 'docker logs family-recipe-ai'"
            exit 1
        fi
        
        warning "Health check not ready yet. Waiting 10 seconds... (Attempt $i/12)"
        sleep 10
    done
}

# Create Firewall in DigitalOcean
create_firewall() {
    log "Setting up DigitalOcean Firewall..."
    
    # Check if firewall already exists
    if doctl compute firewall get "$FIREWALL_NAME" &> /dev/null; then
        warning "Firewall '$FIREWALL_NAME' already exists. Updating it..."
        doctl compute firewall delete "$FIREWALL_NAME" --force
    fi
    
    # Create new firewall
    DROPLET_ID=$(doctl compute droplet get "$DROPLET_NAME" --format ID --no-header)
    
    # Extract domain from the OPENROUTER_SITE_URL in .env.production
    SITE_DOMAIN=$(grep "OPENROUTER_SITE_URL" .env.production | cut -d'=' -f2 | sed 's/https:\/\///')
    
    doctl compute firewall create \
        --name "$FIREWALL_NAME" \
        --droplet-ids "$DROPLET_ID" \
        --inbound-rules "protocol:tcp,ports:22,address:0.0.0.0/0 protocol:tcp,ports:8000,address:$SITE_DOMAIN" \
        --outbound-rules "protocol:icmp,address:0.0.0.0/0 protocol:tcp,ports:all,address:0.0.0.0/0 protocol:udp,ports:all,address:0.0.0.0/0"
    
    success "Firewall configured successfully!"
}

# Main deployment flow
main() {
    log "Starting deployment of Family Recipe AI Service to DigitalOcean..."
    
    # Run all steps
    check_prerequisites
    build_and_push_image
    setup_droplet
    configure_server
    deploy_application
    create_firewall
    verify_deployment
    
    success "===================================================="
    success " Family Recipe AI Service Deployed Successfully!"
    success " Service URL: http://$DROPLET_IP:8000/"
    success " Health check: http://$DROPLET_IP:8000/health"
    success "===================================================="
    
    log "Next steps:"
    log "1. Set up a domain name pointing to $DROPLET_IP"
    log "2. Configure HTTPS using Let's Encrypt"
    log "3. Update the Flask application to use this service"
    log "4. Monitor the logs: ssh -i $SSH_KEY_PATH $DROPLET_SSH_USER@$DROPLET_IP 'docker logs family-recipe-ai'"
}

# Run the main function
main

