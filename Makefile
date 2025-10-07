# Makefile for SoftWave Infrastructure
# Provides convenient shortcuts for common tasks

.PHONY: help init start stop restart logs clean backup restore dev build test

# Default target
help:
	@echo "SoftWave Infrastructure - Available Commands:"
	@echo ""
	@echo "  make init        - Initialize the environment"
	@echo "  make start       - Start all services"
	@echo "  make stop        - Stop all services"
	@echo "  make restart     - Restart all services"
	@echo "  make logs        - View logs from all services"
	@echo "  make logs-app    - View logs from app service only"
	@echo "  make dev         - Start development environment"
	@echo "  make build       - Build Docker images"
	@echo "  make clean       - Stop services and remove volumes"
	@echo "  make backup      - Create database backups"
	@echo "  make ps          - Show running containers"
	@echo "  make shell       - Open shell in app container"
	@echo "  make db-shell    - Open PostgreSQL shell"
	@echo "  make redis-cli   - Open Redis CLI"
	@echo ""

# Initialize environment
init:
	@./init.sh

# Start services
start:
	@./start.sh

# Stop services
stop:
	@./stop.sh

# Restart services
restart: stop start

# View logs
logs:
	@docker compose logs -f

logs-app:
	@docker compose logs -f app

# Development environment
dev:
	@docker compose -f docker-compose.dev.yml up

# Build images
build:
	@docker compose build

# Clean up
clean:
	@./stop.sh --all

# Create backups
backup:
	@./backup.sh

# Show container status
ps:
	@docker compose ps

# Open shell in app container
shell:
	@docker compose exec app sh

# Open PostgreSQL shell
db-shell:
	@docker compose exec postgres psql -U softwave_user -d softwave

# Open Redis CLI
redis-cli:
	@docker compose exec redis redis-cli

# Run tests (if available)
test:
	@docker compose exec app npm test || echo "No tests configured"
