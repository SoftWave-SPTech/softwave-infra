#!/bin/bash

# AWS Deployment Script for SoftWave
# This script deploys the application to AWS ECS

set -e

echo "========================================"
echo "  AWS Deployment Script"
echo "========================================"
echo ""

# Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
ECR_REPOSITORY="${ECR_REPOSITORY:-softwave}"
ECS_CLUSTER="${ECS_CLUSTER:-softwave-cluster}"
ECS_SERVICE="${ECS_SERVICE:-softwave-service}"
TASK_DEFINITION="${TASK_DEFINITION:-softwave-app}"

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

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed"
    exit 1
fi

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}"

print_info "AWS Account: ${AWS_ACCOUNT_ID}"
print_info "ECR Repository: ${ECR_URI}"

# Login to ECR
print_info "Logging in to ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
print_success "Logged in to ECR"

# Build Docker image
print_info "Building Docker image..."
docker build -t ${ECR_REPOSITORY}:latest ../../
print_success "Docker image built"

# Tag image
print_info "Tagging image..."
docker tag ${ECR_REPOSITORY}:latest ${ECR_URI}:latest
docker tag ${ECR_REPOSITORY}:latest ${ECR_URI}:$(date +%Y%m%d-%H%M%S)
print_success "Image tagged"

# Push to ECR
print_info "Pushing image to ECR..."
docker push ${ECR_URI}:latest
print_success "Image pushed to ECR"

# Update ECS service
print_info "Updating ECS service..."
aws ecs update-service \
    --cluster ${ECS_CLUSTER} \
    --service ${ECS_SERVICE} \
    --force-new-deployment \
    --region ${AWS_REGION}
print_success "ECS service updated"

echo ""
print_success "Deployment completed successfully!"
print_info "Monitor deployment: aws ecs describe-services --cluster ${ECS_CLUSTER} --services ${ECS_SERVICE}"
