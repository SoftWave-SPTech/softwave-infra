#!/bin/bash
# Script para build de todas as imagens Docker dos serviços SoftWave
# Execute da raiz do workspace: ./softwave-infra/scripts/build-all-images.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DOCKER_DIR="$SCRIPT_DIR/../docker"

echo "🔨 Building all Docker images..."
echo "Workspace: $WORKSPACE_ROOT"

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Backend Principal
echo -e "${YELLOW}Building backend-softwave...${NC}"
cd "$WORKSPACE_ROOT/backend-softwave"
mvn clean package -DskipTests -q
docker build -f "$DOCKER_DIR/Dockerfile.generic" \
  --build-arg JAR_FILE=target/backend-SoftWave-0.0.2-SNAPSHOT.jar \
  --build-arg SERVICE_NAME=backend \
  --build-arg SERVICE_PORT=8081 \
  -t softwave/backend:latest .

# 2. Auth Service
echo -e "${YELLOW}Building API-AUTH-MAIL...${NC}"
cd "$WORKSPACE_ROOT/API-AUTH-MAIL"
mvn clean package -DskipTests -q
docker build -f Dockerfile -t softwave/auth-service:latest .

# 3. S3 Service
echo -e "${YELLOW}Building API-BUCKET-S3...${NC}"
cd "$WORKSPACE_ROOT/API-BUCKET-S3"
mvn clean package -DskipTests -q
docker build -f "$DOCKER_DIR/Dockerfile.generic" \
  --build-arg JAR_FILE=target/BucketS3-0.0.1-SNAPSHOT.jar \
  --build-arg SERVICE_NAME=s3-service \
  --build-arg SERVICE_PORT=8081 \
  -t softwave/s3-service:latest .

# 4. Gemini Service
echo -e "${YELLOW}Building API-GEMINI-IA...${NC}"
cd "$WORKSPACE_ROOT/API-GEMINI-IA"
mvn clean package -DskipTests -q
docker build -f "$DOCKER_DIR/Dockerfile.generic" \
  --build-arg JAR_FILE=target/api-gemini-ia-0.0.1-SNAPSHOT.jar \
  --build-arg SERVICE_NAME=gemini-service \
  --build-arg SERVICE_PORT=8082 \
  -t softwave/gemini-service:latest .

# 5. Consultas Service
echo -e "${YELLOW}Building api-consultas-softwave...${NC}"
cd "$WORKSPACE_ROOT/api-consultas-softwave"
mvn clean package -DskipTests -q
docker build -f "$DOCKER_DIR/Dockerfile.generic" \
  --build-arg JAR_FILE=target/API-infosimples-Processos1Grau-1.0-SNAPSHOT.jar \
  --build-arg SERVICE_NAME=consultas-service \
  --build-arg SERVICE_PORT=8084 \
  -t softwave/consultas-service:latest .

echo -e "${GREEN}✅ All images built successfully!${NC}"
echo ""
echo "Images created:"
docker images | grep softwave

