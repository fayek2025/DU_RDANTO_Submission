#!/bin/bash

# Script to fix MongoDB authentication issues
# This resets MongoDB with the correct password from .env

set -e

cd "$(dirname "$0")/.." || exit 1

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

log_info "Fixing MongoDB authentication..."
log_warn "This will DELETE all MongoDB data and recreate it with the password from .env"

# Check if .env exists
if [ ! -f .env ]; then
    log_error ".env file not found!"
    log_info "Copy .env.example to .env and configure it"
    exit 1
fi

# Read password from .env
MONGO_PASSWORD=$(grep "^MONGO_INITDB_ROOT_PASSWORD=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'")

if [ -z "$MONGO_PASSWORD" ]; then
    log_error "MONGO_INITDB_ROOT_PASSWORD not found in .env"
    exit 1
fi

log_info "Found password in .env: $MONGO_PASSWORD"
log_info ""

# Stop services and remove volumes
log_info "Stopping services and removing MongoDB volumes..."
make dev-down ARGS="--volumes" || true

# Remove MongoDB volumes manually if they exist
log_info "Cleaning up MongoDB volumes..."
docker volume rm cuet-cse-fest-devops-hackathon-preli_mongo_data_dev 2>/dev/null || true
docker volume rm cuet-cse-fest-devops-hackathon-preli_mongo_config_dev 2>/dev/null || true

# Check MONGO_URI in .env
MONGO_URI=$(grep "^MONGO_URI=" .env | cut -d'=' -f2)

if echo "$MONGO_URI" | grep -q "@mongo"; then
    log_info "MONGO_URI already includes credentials"
else
    log_warn "MONGO_URI doesn't include credentials!"
    log_info "Updating MONGO_URI to include authentication..."
    
    # Extract database name
    DB_NAME=$(echo "$MONGO_URI" | sed 's|.*/\([^?]*\).*|\1|')
    if [ -z "$DB_NAME" ] || [ "$DB_NAME" == "$MONGO_URI" ]; then
        DB_NAME="ecommerce"
    fi
    
    # Update MONGO_URI
    NEW_URI="mongodb://admin:${MONGO_PASSWORD}@mongo:27017/${DB_NAME}?authSource=admin"
    if grep -q "^MONGO_URI=" .env; then
        sed -i "s|^MONGO_URI=.*|MONGO_URI=${NEW_URI}|" .env
        log_info "Updated MONGO_URI in .env"
    else
        echo "MONGO_URI=${NEW_URI}" >> .env
        log_info "Added MONGO_URI to .env"
    fi
fi

log_info ""
log_info "Starting services with new MongoDB configuration..."
make dev-up

log_info ""
log_info "Waiting for MongoDB to initialize..."
sleep 10

# Test connection
log_info "Testing MongoDB connection..."
if docker exec ecom-mongo-dev mongosh -u admin -p "$MONGO_PASSWORD" --authenticationDatabase admin --eval "db.runCommand({ping: 1})" > /dev/null 2>&1; then
    log_info "✓ MongoDB authentication is working!"
    log_info ""
    log_info "Your MongoDB credentials:"
    log_info "  Username: admin"
    log_info "  Password: $MONGO_PASSWORD"
    log_info "  Database: $DB_NAME"
else
    log_error "MongoDB authentication test failed"
    log_info "Check the logs: docker logs ecom-mongo-dev"
    exit 1
fi

