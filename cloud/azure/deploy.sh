#!/bin/bash

# Azure Deployment Script for SoftWave
# This script deploys the application to Azure Container Registry and App Service

set -e

echo "========================================"
echo "  Azure Deployment Script"
echo "========================================"
echo ""

# Configuration
RESOURCE_GROUP="${RESOURCE_GROUP:-softwave-rg}"
LOCATION="${LOCATION:-eastus}"
ACR_NAME="${ACR_NAME:-softwaveacr}"
APP_NAME="${APP_NAME:-softwave-app}"

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

# Check Azure CLI
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed"
    exit 1
fi

# Check if logged in
print_info "Checking Azure login status..."
if ! az account show > /dev/null 2>&1; then
    print_error "Not logged in to Azure. Run 'az login' first."
    exit 1
fi
print_success "Logged in to Azure"

# Create resource group if it doesn't exist
print_info "Ensuring resource group exists..."
az group create --name ${RESOURCE_GROUP} --location ${LOCATION} --output none
print_success "Resource group ready"

# Create ACR if it doesn't exist
print_info "Ensuring Azure Container Registry exists..."
if ! az acr show --name ${ACR_NAME} --resource-group ${RESOURCE_GROUP} > /dev/null 2>&1; then
    az acr create --resource-group ${RESOURCE_GROUP} --name ${ACR_NAME} --sku Basic --output none
    print_success "ACR created"
else
    print_info "ACR already exists"
fi

# Login to ACR
print_info "Logging in to ACR..."
az acr login --name ${ACR_NAME}
print_success "Logged in to ACR"

# Build and push image
print_info "Building Docker image..."
cd ../../
docker build -t ${ACR_NAME}.azurecr.io/softwave:latest .
print_success "Docker image built"

print_info "Pushing image to ACR..."
docker push ${ACR_NAME}.azurecr.io/softwave:latest
print_success "Image pushed to ACR"

cd cloud/azure

# Deploy using ARM template
print_info "Deploying infrastructure..."
az deployment group create \
    --resource-group ${RESOURCE_GROUP} \
    --template-file arm-template.json \
    --parameters administratorLoginPassword="ChangeMe123!" \
    --output none
print_success "Infrastructure deployed"

echo ""
print_success "Deployment completed successfully!"
print_info "View resources: az resource list --resource-group ${RESOURCE_GROUP} --output table"
