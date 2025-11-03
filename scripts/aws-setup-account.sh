#!/usr/bin/env bash
# softwave-infra/scripts/aws-setup-account.sh
# Configura a conta AWS para o deploy do SoftWave (ECR, S3, CloudWatch Logs)
# Uso (Git Bash/WSL/Linux):
#   AWS_REGION=us-east-1 ENV=prod ./aws-setup-account.sh
#   # Opcional: ARTIFACTS_BUCKET=my-custom-bucket ECR_PREFIX=softwave

set -euo pipefail

# --- Funções utilitárias ---
log()  { echo -e "[aws-setup] $*"; }
err()  { echo -e "[aws-setup][ERRO] $*" >&2; }
req()  { command -v "$1" > /dev/null || { err "Dependência ausente: $1"; exit 1; }; }

# Localização do AWS CLI (suporte a Git Bash no Windows)
AWS_BIN=""
find_aws() {
  if command -v aws >/dev/null 2>&1; then
    AWS_BIN="$(command -v aws)"
    return 0
  fi
  # Caminho padrão do instalador no Windows (Git Bash)
  if [ -x "/c/Program Files/Amazon/AWSCLIV2/aws.exe" ]; then
    AWS_BIN="/c/Program Files/Amazon/AWSCLIV2/aws.exe"
    return 0
  fi
  return 1
}

# Wrapper para chamar o binário detectado
aws() {
  if [ -z "$AWS_BIN" ]; then
    err "AWS CLI não encontrado. Instale o AWS CLI v2 ou adicione ao PATH."
    exit 1
  fi
  "$AWS_BIN" "$@"
}

# --- Variáveis ---
AWS_REGION="${AWS_REGION:-us-east-1}"
ENVIRONMENT="${ENV:-prod}"
ECR_PREFIX="${ECR_PREFIX:-softwave}"
ACCOUNT_ID=""

# Repositórios/order fixo para imagens
REPOS=(
  "${ECR_PREFIX}/backend"
  "${ECR_PREFIX}/auth-service"
  "${ECR_PREFIX}/s3-service"
  "${ECR_PREFIX}/gemini-service"
  "${ECR_PREFIX}/consultas-service"
)

# --- Pré-checagens ---
if ! find_aws; then
  err "AWS CLI não encontrado. Instale o AWS CLI v2 (Windows: winget install Amazon.AWSCLI) ou adicione ao PATH."
  err "Opcionalmente, reinicie o Git Bash após a instalação. Caminho comum: C:/Program Files/Amazon/AWSCLIV2/aws.exe"
  exit 1
fi

# Validar credenciais
log "Validando credenciais AWS..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || true)
if [[ -z "$ACCOUNT_ID" || "$ACCOUNT_ID" == "None" ]]; then
  err "Não foi possível obter o Account ID. Configure 'aws configure' ou variáveis de ambiente."
  exit 1
fi
log "Account ID: $ACCOUNT_ID | Região: $AWS_REGION | Ambiente: $ENVIRONMENT"

# Bucket de artefatos (globalmente único)
ARTIFACTS_BUCKET_DEFAULT="${ECR_PREFIX}-artifacts-${ENVIRONMENT}-${ACCOUNT_ID}"
ARTIFACTS_BUCKET="${ARTIFACTS_BUCKET:-$ARTIFACTS_BUCKET_DEFAULT}"

# --- Criar Bucket S3 de artefatos/config ---
log "Garantindo Bucket S3: s3://${ARTIFACTS_BUCKET}"
if aws s3api head-bucket --bucket "$ARTIFACTS_BUCKET" 2>/dev/null; then
  log "Bucket já existe."
else
  if [[ "$AWS_REGION" == "us-east-1" ]]; then
    aws s3api create-bucket --bucket "$ARTIFACTS_BUCKET" --region "$AWS_REGION"
  else
    aws s3api create-bucket --bucket "$ARTIFACTS_BUCKET" --region "$AWS_REGION" \
      --create-bucket-configuration LocationConstraint="$AWS_REGION"
  fi
  log "Bucket criado: $ARTIFACTS_BUCKET"
fi

# Habilitar versionamento (recomendado)
log "Habilitando versionamento no bucket..."
aws s3api put-bucket-versioning --bucket "$ARTIFACTS_BUCKET" --versioning-configuration Status=Enabled

# --- Criar repositórios ECR ---
log "Garantindo repositórios ECR..."
for repo in "${REPOS[@]}"; do
  if aws ecr describe-repositories --repository-names "$repo" --region "$AWS_REGION" >/dev/null 2>&1; then
    log "ECR repo existe: $repo"
  else
    aws ecr create-repository --repository-name "$repo" --region "$AWS_REGION" >/dev/null
    log "ECR repo criado: $repo"
  fi
  # Definir política de retenção de imagens (opcional)
  aws ecr put-lifecycle-policy \
    --repository-name "$repo" \
    --lifecycle-policy-text '{
      "rules": [
        {"rulePriority": 1, "description": "Manter últimas 15 imagens", "selection": {"tagStatus": "any", "countType": "imageCountMoreThan", "countNumber": 15}, "action": {"type": "expire"}}
      ]
    }' \
  --region "$AWS_REGION" >/dev/null || true
done

echo
log "Criando grupos de logs no CloudWatch (se não existirem)..."
LOG_GROUP_BASE="/softwave/${ENVIRONMENT}"
for name in docker nginx backend auth s3 gemini consultas; do
  GROUP_NAME="${LOG_GROUP_BASE}/${name}"
  if ! aws logs describe-log-groups --log-group-name-prefix "$GROUP_NAME" --region "$AWS_REGION" | grep -q 'logGroupName'; then
    aws logs create-log-group --log-group-name "$GROUP_NAME" --region "$AWS_REGION" || true
    log "Log group criado: $GROUP_NAME"
  else
    log "Log group existe: $GROUP_NAME"
  fi
  # Definir retenção (30 dias por padrão)
  aws logs put-retention-policy --log-group-name "$GROUP_NAME" --retention-in-days 30 --region "$AWS_REGION" || true
done

echo
log "Resumo:"
cat <<EOF
- Account:        $ACCOUNT_ID
- Region:         $AWS_REGION
- Environment:    $ENVIRONMENT
- S3 Bucket:      s3://$ARTIFACTS_BUCKET
- ECR repos:      ${REPOS[*]}
- Log groups:     ${LOG_GROUP_BASE}/*

Dica: execute agora o script build-and-push.sh para publicar as imagens, e upload-config-to-s3.sh
para enviar docker-compose e nginx.conf ao bucket.
EOF
