#!/bin/bash

# SoftWave Infrastructure Initialization Script
# This script initializes the project environment

set -e

echo "========================================"
echo "  SoftWave Infrastructure Setup"
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

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi
print_success "Docker is installed"

# Check if Docker Compose is installed
if ! command -v docker compose &> /dev/null && ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi
print_success "Docker Compose is installed"

# Create necessary directories
print_info "Creating necessary directories..."
mkdir -p logs
mkdir -p scripts
mkdir -p nginx
mkdir -p cloud/aws
mkdir -p cloud/azure
mkdir -p cloud/gcp

print_success "Directories created"

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    print_info "Creating .env file..."
    cat > .env << EOF
# Application Configuration
NODE_ENV=development
APP_PORT=3000

# Database Configuration
DB_HOST=postgres
DB_PORT=5432
DB_NAME=softwave
DB_USER=softwave_user
DB_PASSWORD=softwave_pass

# Redis Configuration
REDIS_HOST=redis
REDIS_PORT=6379

# Security (Change these in production!)
JWT_SECRET=your-secret-key-change-this
API_KEY=your-api-key-change-this
EOF
    print_success ".env file created"
else
    print_info ".env file already exists, skipping..."
fi

# Create init.sql if it doesn't exist
if [ ! -f scripts/init.sql ]; then
    print_info "Creating init.sql file..."
    cat > scripts/init.sql << EOF
-- SoftWave Database Initialization Script
-- This script runs when the PostgreSQL container is first created

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create example tables
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(255) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);

-- Insert sample data (optional, remove in production)
-- INSERT INTO users (username, email) VALUES ('admin', 'admin@softwave.com');
EOF
    print_success "init.sql created"
else
    print_info "init.sql already exists, skipping..."
fi

# Create nginx configuration if it doesn't exist
if [ ! -f nginx/nginx.conf ]; then
    print_info "Creating nginx configuration..."
    cat > nginx/nginx.conf << EOF
events {
    worker_connections 1024;
}

http {
    upstream app_backend {
        server app:3000;
    }

    server {
        listen 80;
        server_name localhost;

        location / {
            proxy_pass http://app_backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host \$host;
            proxy_cache_bypass \$http_upgrade;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
}
EOF
    print_success "nginx.conf created"
else
    print_info "nginx.conf already exists, skipping..."
fi

# Pull Docker images
print_info "Pulling Docker images (this may take a while)..."
if docker compose pull; then
    print_success "Docker images pulled successfully"
else
    print_error "Failed to pull Docker images"
    exit 1
fi

echo ""
print_success "Initialization complete!"
echo ""
echo "Next steps:"
echo "  1. Review and update the .env file with your configuration"
echo "  2. Run './start.sh' to start the services"
echo "  3. Access the application at http://localhost:3000"
echo ""
