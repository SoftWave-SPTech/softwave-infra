#!/usr/bin/env bash
# softwave-infra/scripts/upload-config-to-s3.sh
# Publica arquivos de configuração (docker-compose.prod.yml, nginx.conf e systemd unit) para S3
# Uso:
#   AWS_REGION=us-east-1 ENV=prod ARTIFACTS_BUCKET=<bucket> ./upload-config-to-s3.sh

set -euo pipefail

log() { echo -e "[upload-config] $*"; }
err() { echo -e "[upload-config][ERRO] $*" >&2; }
req() { command -v "$1" >/dev/null || { err "Dependência ausente: $1"; exit 1; }; }

req aws

AWS_REGION="${AWS_REGION:-us-east-1}"
ENVIRONMENT="${ENV:-prod}"
BUCKET="${ARTIFACTS_BUCKET:-}"

if [[ -z "$BUCKET" ]]; then
  err "Defina ARTIFACTS_BUCKET=sua-bucket antes de executar."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)" # softwave-infra

COMPOSE_FILE="$ROOT_DIR/docker-compose.prod.yml"
NGINX_FILE="$ROOT_DIR/nginx/nginx.conf"
SYSTEMD_FILE="$ROOT_DIR/systemd/softwave-docker-compose.service"

[[ -f "$COMPOSE_FILE" ]] || { err "docker-compose.prod.yml não encontrado em $COMPOSE_FILE"; exit 1; }
[[ -f "$NGINX_FILE" ]]   || { err "nginx.conf não encontrado em $NGINX_FILE"; exit 1; }
[[ -f "$SYSTEMD_FILE" ]] || { err "systemd unit não encontrado em $SYSTEMD_FILE"; exit 1; }

DEST_PREFIX="s3://${BUCKET}/config/${ENVIRONMENT}"

log "Enviando arquivos para ${DEST_PREFIX} ..."
aws s3 cp "$COMPOSE_FILE" "${DEST_PREFIX}/docker-compose.prod.yml" --region "$AWS_REGION"
aws s3 cp "$NGINX_FILE"   "${DEST_PREFIX}/nginx.conf"               --region "$AWS_REGION"
aws s3 cp "$SYSTEMD_FILE"  "${DEST_PREFIX}/softwave-docker-compose.service" --region "$AWS_REGION"

log "✅ Upload concluído:" 
aws s3 ls "${DEST_PREFIX}/" --region "$AWS_REGION" || true
