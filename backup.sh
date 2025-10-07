#!/bin/bash

# Backup script for SoftWave databases
# Creates timestamped backups of PostgreSQL and Redis data

set -e

echo "========================================"
echo "  SoftWave Backup Script"
echo "========================================"
echo ""

# Configuration
BACKUP_DIR="${BACKUP_DIR:-./backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Create backup directory
mkdir -p $BACKUP_DIR
print_info "Backup directory: $BACKUP_DIR"

# Check if containers are running
if ! docker compose ps | grep -q "Up"; then
    print_error "No containers are running. Please start services first."
    exit 1
fi

# Backup PostgreSQL
print_info "Backing up PostgreSQL database..."
POSTGRES_BACKUP="$BACKUP_DIR/postgres_$TIMESTAMP.sql"

docker compose exec -T postgres pg_dump -U softwave_user softwave > $POSTGRES_BACKUP

if [ $? -eq 0 ]; then
    # Compress backup
    gzip $POSTGRES_BACKUP
    print_success "PostgreSQL backup created: ${POSTGRES_BACKUP}.gz"
else
    print_error "Failed to backup PostgreSQL"
fi

# Backup Redis
print_info "Backing up Redis data..."
REDIS_BACKUP="$BACKUP_DIR/redis_$TIMESTAMP.rdb"

docker compose exec -T redis redis-cli SAVE > /dev/null
docker compose cp redis:/data/dump.rdb $REDIS_BACKUP

if [ $? -eq 0 ]; then
    gzip $REDIS_BACKUP
    print_success "Redis backup created: ${REDIS_BACKUP}.gz"
else
    print_error "Failed to backup Redis"
fi

# Cleanup old backups (keep last 7 days)
print_info "Cleaning up old backups (keeping last 7 days)..."
find $BACKUP_DIR -name "*.gz" -type f -mtime +7 -delete
print_success "Cleanup completed"

echo ""
print_success "Backup completed successfully!"
print_info "Backups saved to: $BACKUP_DIR"
