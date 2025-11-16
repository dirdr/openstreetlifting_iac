#!/bin/bash
set -e

# ==============================================================================
# OpenStreetLifting - Production Deployment Setup Script
# ==============================================================================
# This script helps configure and deploy the production environment.
#
# Usage:
#   ./setup.sh
# ==============================================================================

echo "🏋️  OpenStreetLifting - Production Deployment Setup"
echo "===================================================="
echo ""

# Check if running as root (not recommended)
if [ "$EUID" -eq 0 ]; then
    echo "⚠️  Warning: Running as root is not recommended."
    echo "   Consider running as a non-root user with Docker permissions."
    echo ""
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker is not installed."
    echo "   Install Docker Engine: https://docs.docker.com/engine/install/"
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Error: Docker Compose is not installed."
    echo "   Install Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi

echo "✅ Docker detected"

# Check if Traefik network exists
if ! docker network inspect traefik_public &> /dev/null; then
    echo "⚠️  Warning: traefik_public network does not exist."
    read -p "   Do you want to create it now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker network create traefik_public
        echo "✅ traefik_public network created"
    else
        echo "❌ Error: traefik_public network is required."
        echo "   Create it with: docker network create traefik_public"
        exit 1
    fi
else
    echo "✅ traefik_public network found"
fi

# Check if .env exists
if [ -f .env ]; then
    echo "⚠️  .env file already exists."
    read -p "   Do you want to reconfigure it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "   Using existing .env file."
        SKIP_CONFIG=true
    fi
fi

if [ "$SKIP_CONFIG" != true ]; then
    echo ""
    echo "📝 Configuring production environment..."
    echo ""

    # Copy template
    cp .env.example .env

    # Database password
    echo "🔐 Database Configuration"
    echo "   Current DB_PASSWORD: CHANGE_ME_IN_PRODUCTION"
    read -p "   Enter strong database password (or press Enter to auto-generate): " DB_PASS
    if [ -z "$DB_PASS" ]; then
        DB_PASS=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
        echo "   ✅ Generated: $DB_PASS"
    fi
    sed -i.bak "s/DB_PASSWORD=CHANGE_ME_IN_PRODUCTION/DB_PASSWORD=$DB_PASS/" .env

    # API Keys
    echo ""
    echo "🔑 API Authentication"
    echo "   Current API_KEYS: CHANGE_ME_IN_PRODUCTION"
    read -p "   Enter API key (or press Enter to auto-generate): " API_KEY
    if [ -z "$API_KEY" ]; then
        API_KEY=$(openssl rand -hex 32)
        echo "   ✅ Generated: $API_KEY"
    fi
    sed -i.bak "s/API_KEYS=CHANGE_ME_IN_PRODUCTION/API_KEYS=$API_KEY/" .env

    # Clean up backup files
    rm -f .env.bak

    echo ""
    echo "✅ .env file configured"
    echo "   ⚠️  IMPORTANT: Keep your .env file secure and never commit it to version control!"
fi

# Verify DNS (optional)
echo ""
read -p "🌐 Verify DNS configuration for api.openstreetlifting.org? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if command -v dig &> /dev/null; then
        echo "   Checking DNS..."
        dig +short api.openstreetlifting.org A
    else
        echo "   'dig' command not found. Install dnsutils to check DNS."
    fi
fi

# Security checklist
echo ""
echo "🔒 Security Checklist:"
echo "   [ ] Database password is strong and unique"
echo "   [ ] API keys are secure (use: openssl rand -hex 32)"
echo "   [ ] DNS points to this server"
echo "   [ ] Traefik is configured with Let's Encrypt"
echo "   [ ] Firewall allows ports 80, 443"
echo "   [ ] Database port is restricted (consider commenting out in docker-compose.yaml)"
echo "   [ ] Backup strategy is in place"
echo ""

read -p "Ready to deploy? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled. Run this script again when ready."
    exit 0
fi

echo ""
echo "🚀 Deploying services..."
echo ""

# Pull latest images
echo "📥 Pulling latest images..."
if command -v docker-compose &> /dev/null; then
    docker-compose pull
else
    docker compose pull
fi

# Start services
echo "🐳 Starting services..."
if command -v docker-compose &> /dev/null; then
    docker-compose up -d
else
    docker compose up -d
fi

echo ""
echo "⏳ Waiting for services to start..."
sleep 10

# Check service status
if command -v docker-compose &> /dev/null; then
    docker-compose ps
else
    docker compose ps
fi

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📌 Service Information:"
echo "   • API URL:              https://api.openstreetlifting.org"
echo "   • Swagger UI:           https://api.openstreetlifting.org/swagger-ui/"
echo "   • Database:             postgres:5432 (internal)"
echo ""
echo "📚 Management Commands:"
echo "   • View logs:            docker-compose logs -f"
echo "   • Stop services:        docker-compose down"
echo "   • Restart services:     docker-compose restart"
echo "   • Update backend:       docker-compose pull backend && docker-compose up -d backend"
echo ""
echo "🔐 IMPORTANT: Save your credentials securely!"
echo "   Database Password:     (stored in .env)"
echo "   API Key:               (stored in .env)"
echo ""
echo "🎉 Your OpenStreetLifting API is now live!"
