#!/bin/bash

# Health check script for Docker containers
# This script checks if the application is responding correctly

set -e

# Configuration
HOST="${HOST:-localhost}"
PORT="${PORT:-3000}"
ENDPOINT="${ENDPOINT:-/health}"
TIMEOUT="${TIMEOUT:-5}"

# Make request
if command -v curl &> /dev/null; then
    response=$(curl -sf --max-time $TIMEOUT http://${HOST}:${PORT}${ENDPOINT} || echo "FAILED")
elif command -v wget &> /dev/null; then
    response=$(wget -qO- --timeout=$TIMEOUT http://${HOST}:${PORT}${ENDPOINT} || echo "FAILED")
else
    echo "Neither curl nor wget available"
    exit 1
fi

# Check response
if [ "$response" != "FAILED" ]; then
    exit 0
else
    exit 1
fi
