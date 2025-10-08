#!/bin/bash

# SoftWave Infrastructure Stop Script
# This script stops all running services

set -e

echo "========================================"
echo "  Stopping SoftWave Services"
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

# Parse command line arguments
REMOVE_VOLUMES=""
REMOVE_IMAGES=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --volumes|-v)
            REMOVE_VOLUMES="-v"
            shift
            ;;
        --images|-i)
            REMOVE_IMAGES="--rmi all"
            shift
            ;;
        --all|-a)
            REMOVE_VOLUMES="-v"
            REMOVE_IMAGES="--rmi all"
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Stop services
print_info "Stopping services..."
docker compose down $REMOVE_VOLUMES $REMOVE_IMAGES

if [ $? -eq 0 ]; then
    print_success "Services stopped successfully!"
    
    if [ -n "$REMOVE_VOLUMES" ]; then
        print_info "Volumes removed"
    fi
    
    if [ -n "$REMOVE_IMAGES" ]; then
        print_info "Images removed"
    fi
else
    print_error "Failed to stop services"
    exit 1
fi

echo ""
print_info "To start services again, run: ./start.sh"
