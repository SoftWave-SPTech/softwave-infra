#!/bin/bash

# Logs viewing script
# This script helps view logs from Docker containers

set -e

echo "========================================"
echo "  SoftWave Logs Viewer"
echo "========================================"
echo ""

# Color codes
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Parse arguments
SERVICE=""
FOLLOW="-f"
TAIL="100"

while [[ $# -gt 0 ]]; do
    case $1 in
        --no-follow)
            FOLLOW=""
            shift
            ;;
        --tail)
            TAIL="$2"
            shift 2
            ;;
        *)
            SERVICE="$1"
            shift
            ;;
    esac
done

# Show available services if none specified
if [ -z "$SERVICE" ]; then
    print_info "Available services:"
    docker compose ps --services
    echo ""
    print_info "Usage: ./logs.sh [service] [--no-follow] [--tail N]"
    print_info "Example: ./logs.sh app"
    print_info "Example: ./logs.sh postgres --tail 50"
    print_info "Example: ./logs.sh --no-follow"
    exit 0
fi

# View logs
print_info "Viewing logs for: $SERVICE"
echo ""

docker compose logs $FOLLOW --tail=$TAIL $SERVICE
