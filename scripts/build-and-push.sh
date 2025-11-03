#!/usr/bin/env bash
# softwave-infra/scripts/build-and-push.sh
# Faz build das imagens Docker e publica no ECR da conta atual
# Uso:
#   AWS_REGION=us-east-1 ./build-and-push.sh [--skip-build]

set -euo pipefail

log() { echo -e "[build-push] $*"; }
err() { echo -e "[build-push][ERRO] $*" >&2; }
req() { command -v "$1" >/dev/null || { err "Dependência ausente: $1"; exit 1; }; }

AWS_REGION="${AWS_REGION:-us-east-1}"
ECR_PREFIX="${ECR_PREFIX:-softwave}"
SKIP_BUILD="false"

if [[ "${1:-}" == "--skip-build" ]]; then
  SKIP_BUILD="true"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

req aws
req docker

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URL="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Build local images
if [[ "$SKIP_BUILD" != "true" ]]; then
  log "Executando build de todas as imagens..."
  bash "$SCRIPT_DIR/build-all-images.sh"
else
  log "Pulando etapa de build (--skip-build)"
fi

# Login no ECR
log "Efetuando login no ECR..."
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_URL"

# Mapeamento imagem local -> repositório ECR
IMAGES=(
  "softwave/backend:latest|${ECR_PREFIX}/backend:latest"
  "softwave/auth-service:latest|${ECR_PREFIX}/auth-service:latest"
  "softwave/s3-service:latest|${ECR_PREFIX}/s3-service:latest"
  "softwave/gemini-service:latest|${ECR_PREFIX}/gemini-service:latest"
  "softwave/consultas-service:latest|${ECR_PREFIX}/consultas-service:latest"
)

for mapping in "${IMAGES[@]}"; do
  SRC_IMAGE="${mapping%%|*}"
  DST_REPO_TAG="${mapping##*|}"
  DST_IMAGE="${ECR_URL}/${DST_REPO_TAG}"

  log "Tagging: $SRC_IMAGE -> $DST_IMAGE"
  docker tag "$SRC_IMAGE" "$DST_IMAGE"

  log "Pushing: $DST_IMAGE"
  docker push "$DST_IMAGE"

done

log "✅ Publicação concluída."
