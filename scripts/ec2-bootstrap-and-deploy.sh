#!/usr/bin/env bash
# softwave-infra/scripts/ec2-bootstrap-and-deploy.sh
# Para rodar NA EC2 (Amazon Linux 2). Instala Docker/Compose/AWS CLI, baixa configs do S3, 
# loga no ECR e sobe os serviços via docker-compose + systemd.
# Uso na EC2:
#   sudo bash ec2-bootstrap-and-deploy.sh \ 
#     --region us-east-1 \ 
#     --bucket <ARTIFACTS_BUCKET> \ 
#     --env prod \ 
#     --account <ACCOUNT_ID>

set -euo pipefail

REGION="us-east-1"
BUCKET=""
ENVIRONMENT="prod"
ACCOUNT_ID=""
ECR_PREFIX="${ECR_PREFIX:-softwave}"
WORKDIR="/opt/softwave"

log() { echo -e "[ec2-deploy] $*"; }
err() { echo -e "[ec2-deploy][ERRO] $*" >&2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --region) REGION="$2"; shift 2;;
    --bucket) BUCKET="$2"; shift 2;;
    --env) ENVIRONMENT="$2"; shift 2;;
    --account) ACCOUNT_ID="$2"; shift 2;;
    *) err "Parâmetro desconhecido: $1"; exit 1;;
  esac
done

[[ -n "$BUCKET" ]] || { err "Informe --bucket <ARTIFACTS_BUCKET>."; exit 1; }
[[ -n "$ACCOUNT_ID" ]] || { 
  log "Obtendo ACCOUNT_ID via STS..."; 
  ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || true)
  [[ -n "$ACCOUNT_ID" && "$ACCOUNT_ID" != "None" ]] || { err "Falha ao descobrir ACCOUNT_ID. Use --account <id>."; exit 1; }
}

log "Região: $REGION | ENV: $ENVIRONMENT | Bucket: $BUCKET | Account: $ACCOUNT_ID"

# --- Atualizações e dependências ---
yum update -y
amazon-linux-extras install docker -y || yum install -y docker
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user || true

# Docker Compose v2
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# AWS CLI v2 (se necessário)
if ! command -v aws &>/dev/null; then
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip -q awscliv2.zip
  ./aws/install
  rm -rf aws awscliv2.zip
fi

# --- Preparar diretórios ---
mkdir -p "$WORKDIR"
chown ec2-user:ec2-user "$WORKDIR"

# --- Baixar configurações do S3 ---
log "Baixando docker-compose, nginx.conf e systemd unit do S3..."
aws s3 cp "s3://${BUCKET}/config/${ENVIRONMENT}/docker-compose.prod.yml" "${WORKDIR}/docker-compose.prod.yml" --region "$REGION"
aws s3 cp "s3://${BUCKET}/config/${ENVIRONMENT}/softwave-docker-compose.service" \
  "/etc/systemd/system/softwave-docker-compose.service" --region "$REGION"

# .env é sensível; opcionalmente manter no S3. Caso exista, baixar; senão, criar placeholder
if aws s3 ls "s3://${BUCKET}/config/${ENVIRONMENT}/.env" --region "$REGION" >/dev/null 2>&1; then
  log "Baixando .env do S3..."
  aws s3 cp "s3://${BUCKET}/config/${ENVIRONMENT}/.env" "${WORKDIR}/.env" --region "$REGION"
else
  log "Nenhum .env no S3. Criando placeholder em ${WORKDIR}/.env (edite com valores reais)."
  cat > "${WORKDIR}/.env" <<'EOF'
# Preencha com suas variáveis de produção
SPRING_DATASOURCE_URL=
SPRING_DATASOURCE_USERNAME=
SPRING_DATASOURCE_PASSWORD=
JWT_SECRET=
AWS_REGION=us-east-1
AWS_S3_BUCKET=
# ... demais variáveis necessárias
EOF
fi

# --- Login no ECR e pre-pull de imagens ---
ECR_URL="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
log "Fazendo login no ECR: ${ECR_URL}"
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ECR_URL"

for repo in backend auth-service s3-service gemini-service consultas-service; do
  docker pull "${ECR_URL}/${ECR_PREFIX}/${repo}:latest" || true
done

# --- Habilitar serviço systemd ---
systemctl daemon-reload
systemctl enable softwave-docker-compose || true

# --- Subir serviços ---
log "Subindo serviços com docker-compose..."
/usr/local/bin/docker-compose -f "${WORKDIR}/docker-compose.prod.yml" up -d

# Validar
sleep 5
systemctl status softwave-docker-compose --no-pager || true

echo "✅ Deploy concluído. Use 'docker ps' e 'journalctl -u softwave-docker-compose -f' para logs."
