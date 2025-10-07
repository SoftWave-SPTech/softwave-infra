#!/bin/bash

# SoftWave Infrastructure Start Script
# This script starts all services defined in docker-compose.yml

set -e

echo "========================================"
echo "  Starting SoftWave Services"
echo "========================================"
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Check if .env file exists
if [ ! -f .env ]; then
    print_error ".env file not found. Please run ./init.sh first."
    exit 1
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

# Parse command line arguments
DETACHED="-d"
BUILD=""
SERVICES=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --no-detach|-f|--foreground)
            DETACHED=""
            shift
            ;;
        --build|-b)
            BUILD="--build"
            shift
            ;;
        *)
            SERVICES="$SERVICES $1"
            shift
            ;;
    esac
done

# Build and start services
print_info "Starting services..."

if [ -z "$DETACHED" ]; then
    print_info "Running in foreground mode (Press Ctrl+C to stop)"
    docker compose up $BUILD $SERVICES
else
    docker compose up $DETACHED $BUILD $SERVICES
    
    if [ $? -eq 0 ]; then
        print_success "Services started successfully!"
        echo ""
        print_info "Service URLs:"
        echo "  - Application: http://localhost:3000"
        echo "  - Nginx Proxy: http://localhost:80"
        echo "  - PostgreSQL: localhost:5432"
        echo "  - Redis: localhost:6379"
        echo ""
        print_info "View logs with: docker compose logs -f"
        print_info "Stop services with: ./stop.sh"
    else
        print_error "Failed to start services"
        exit 1
    fi
fi
