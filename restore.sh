#!/bin/bash

# Restore script for SoftWave databases
# Restores PostgreSQL and Redis data from backups

set -e

echo "========================================"
echo "  SoftWave Restore Script"
echo "========================================"
echo ""

# Configuration
BACKUP_DIR="${BACKUP_DIR:-./backups}"

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

# Check if backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    print_error "Backup directory not found: $BACKUP_DIR"
    exit 1
fi

# List available backups
print_info "Available PostgreSQL backups:"
ls -lh $BACKUP_DIR/postgres_*.sql.gz 2>/dev/null || echo "No PostgreSQL backups found"
echo ""

print_info "Available Redis backups:"
ls -lh $BACKUP_DIR/redis_*.rdb.gz 2>/dev/null || echo "No Redis backups found"
echo ""

# Parse arguments
POSTGRES_BACKUP=""
REDIS_BACKUP=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --postgres)
            POSTGRES_BACKUP="$2"
            shift 2
            ;;
        --redis)
            REDIS_BACKUP="$2"
            shift 2
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check if containers are running
if ! docker compose ps | grep -q "Up"; then
    print_error "No containers are running. Please start services first."
    exit 1
fi

# Restore PostgreSQL
if [ -n "$POSTGRES_BACKUP" ]; then
    if [ ! -f "$POSTGRES_BACKUP" ]; then
        print_error "PostgreSQL backup file not found: $POSTGRES_BACKUP"
        exit 1
    fi
    
    print_info "Restoring PostgreSQL from: $POSTGRES_BACKUP"
    
    # Decompress if needed
    if [[ $POSTGRES_BACKUP == *.gz ]]; then
        gunzip -c $POSTGRES_BACKUP | docker compose exec -T postgres psql -U softwave_user softwave
    else
        cat $POSTGRES_BACKUP | docker compose exec -T postgres psql -U softwave_user softwave
    fi
    
    if [ $? -eq 0 ]; then
        print_success "PostgreSQL restored successfully"
    else
        print_error "Failed to restore PostgreSQL"
    fi
fi

# Restore Redis
if [ -n "$REDIS_BACKUP" ]; then
    if [ ! -f "$REDIS_BACKUP" ]; then
        print_error "Redis backup file not found: $REDIS_BACKUP"
        exit 1
    fi
    
    print_info "Restoring Redis from: $REDIS_BACKUP"
    
    # Stop Redis, restore file, start Redis
    docker compose stop redis
    
    # Decompress if needed
    if [[ $REDIS_BACKUP == *.gz ]]; then
        gunzip -c $REDIS_BACKUP > /tmp/dump.rdb
        docker compose cp /tmp/dump.rdb redis:/data/dump.rdb
        rm /tmp/dump.rdb
    else
        docker compose cp $REDIS_BACKUP redis:/data/dump.rdb
    fi
    
    docker compose start redis
    
    if [ $? -eq 0 ]; then
        print_success "Redis restored successfully"
    else
        print_error "Failed to restore Redis"
    fi
fi

# Show usage if no arguments provided
if [ -z "$POSTGRES_BACKUP" ] && [ -z "$REDIS_BACKUP" ]; then
    echo "Usage: ./restore.sh [--postgres <backup_file>] [--redis <backup_file>]"
    echo ""
    echo "Examples:"
    echo "  ./restore.sh --postgres $BACKUP_DIR/postgres_20240101_120000.sql.gz"
    echo "  ./restore.sh --redis $BACKUP_DIR/redis_20240101_120000.rdb.gz"
    echo "  ./restore.sh --postgres <file> --redis <file>"
fi
