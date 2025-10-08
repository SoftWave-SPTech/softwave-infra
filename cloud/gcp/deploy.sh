#!/bin/bash

# GCP Deployment Script for SoftWave
# This script deploys the application to Google Cloud Platform

set -e

echo "========================================"
echo "  GCP Deployment Script"
echo "========================================"
echo ""

# Configuration
PROJECT_ID="${GCP_PROJECT_ID:-your-project-id}"
REGION="${GCP_REGION:-us-central1}"
SERVICE_NAME="${SERVICE_NAME:-softwave-app}"
IMAGE_NAME="gcr.io/${PROJECT_ID}/softwave"

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

# Check gcloud CLI
if ! command -v gcloud &> /dev/null; then
    print_error "gcloud CLI is not installed"
    exit 1
fi

# Check if logged in
print_info "Checking GCP authentication..."
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    print_error "Not authenticated with GCP. Run 'gcloud auth login' first."
    exit 1
fi
print_success "Authenticated with GCP"

# Set project
print_info "Setting project to ${PROJECT_ID}..."
gcloud config set project ${PROJECT_ID}
print_success "Project set"

# Enable required APIs
print_info "Enabling required APIs..."
gcloud services enable \
    run.googleapis.com \
    sql-component.googleapis.com \
    sqladmin.googleapis.com \
    redis.googleapis.com \
    containerregistry.googleapis.com \
    cloudbuild.googleapis.com
print_success "APIs enabled"

# Build image using Cloud Build
print_info "Building Docker image with Cloud Build..."
cd ../../
gcloud builds submit --tag ${IMAGE_NAME}:latest .
print_success "Image built and pushed to GCR"

cd cloud/gcp

# Deploy to Cloud Run
print_info "Deploying to Cloud Run..."
gcloud run deploy ${SERVICE_NAME} \
    --image ${IMAGE_NAME}:latest \
    --platform managed \
    --region ${REGION} \
    --allow-unauthenticated \
    --port 3000 \
    --cpu 1 \
    --memory 512Mi \
    --min-instances 1 \
    --max-instances 10

if [ $? -eq 0 ]; then
    print_success "Deployed to Cloud Run"
    
    # Get service URL
    SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} \
        --platform managed \
        --region ${REGION} \
        --format 'value(status.url)')
    
    echo ""
    print_success "Deployment completed successfully!"
    print_info "Service URL: ${SERVICE_URL}"
else
    print_error "Failed to deploy to Cloud Run"
    exit 1
fi
