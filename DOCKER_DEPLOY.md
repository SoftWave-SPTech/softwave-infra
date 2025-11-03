# 🐳 Guia de Deploy com Docker Compose + Systemd

Este guia explica como fazer deploy dos serviços SoftWave em EC2 usando Docker Compose gerenciado por Systemd.

## 📋 Visão Geral

A arquitetura usa:
- **Docker Compose**: Orquestra todos os serviços em containers
- **Systemd**: Gerencia o Docker Compose como serviço do sistema
- **EC2**: Instâncias na sub-rede privada (10.0.0.128/25)

## 🏗️ Arquitetura

```
EC2 Backend (10.0.0.130 ou 10.0.0.131)
├── Docker Engine
├── Docker Compose (softwave-docker-compose.service)
└── Containers:
    ├── backend-1 (porta 8081)
    ├── backend-2 (porta 8082)
    ├── auth-service (porta 8083)
    ├── s3-service (porta 8081) - em outra instância se necessário
    ├── gemini-service (porta 8082) - em outra instância se necessário
    └── consultas-service (porta 8084)
```

## 📦 Pré-requisitos

1. **Build das imagens Docker** (local ou CI/CD)
2. **Push das imagens** para ECR (AWS) ou Docker Hub
3. **EC2 com bootstrap-backend.sh** executado

## 🚀 Passo a Passo do Deploy

### 1. Build das Imagens Docker

Para cada serviço, crie a imagem Docker:

```bash
# Backend Principal
cd backend-softwave
mvn clean package -DskipTests
docker build -f ../softwave-infra/docker/Dockerfile.generic \
  --build-arg JAR_FILE=target/backend-SoftWave-0.0.2-SNAPSHOT.jar \
  --build-arg SERVICE_NAME=backend \
  --build-arg SERVICE_PORT=8081 \
  -t softwave/backend:latest .

# Auth Service
cd ../API-AUTH-MAIL
mvn clean package -DskipTests
docker build -f Dockerfile -t softwave/auth-service:latest .

# S3 Service
cd ../API-BUCKET-S3
mvn clean package -DskipTests
docker build -f ../softwave-infra/docker/Dockerfile.generic \
  --build-arg JAR_FILE=target/BucketS3-0.0.1-SNAPSHOT.jar \
  --build-arg SERVICE_NAME=s3-service \
  --build-arg SERVICE_PORT=8081 \
  -t softwave/s3-service:latest .

# Gemini Service
cd ../API-GEMINI-IA
mvn clean package -DskipTests
docker build -f ../softwave-infra/docker/Dockerfile.generic \
  --build-arg JAR_FILE=target/api-gemini-ia-0.0.1-SNAPSHOT.jar \
  --build-arg SERVICE_NAME=gemini-service \
  --build-arg SERVICE_PORT=8082 \
  -t softwave/gemini-service:latest .

# Consultas Service
cd ../api-consultas-softwave
mvn clean package -DskipTests
docker build -f ../softwave-infra/docker/Dockerfile.generic \
  --build-arg JAR_FILE=target/API-infosimples-Processos1Grau-1.0-SNAPSHOT.jar \
  --build-arg SERVICE_NAME=consultas-service \
  --build-arg SERVICE_PORT=8084 \
  -t softwave/consultas-service:latest .
```

### 2. Push para ECR (AWS)

```bash
# Autenticar no ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

# Criar repositórios (se não existir)
aws ecr create-repository --repository-name softwave/backend --region us-east-1
aws ecr create-repository --repository-name softwave/auth-service --region us-east-1
aws ecr create-repository --repository-name softwave/s3-service --region us-east-1
aws ecr create-repository --repository-name softwave/gemini-service --region us-east-1
aws ecr create-repository --repository-name softwave/consultas-service --region us-east-1

# Tag e push
docker tag softwave/backend:latest <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/softwave/backend:latest
docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/softwave/backend:latest

# Repetir para todos os serviços
```

### 3. Atualizar docker-compose.prod.yml com URLs do ECR

Edite `docker-compose.prod.yml` e substitua `softwave/backend:latest` por:
```yaml
image: <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/softwave/backend:latest
```

### 4. Deploy na EC2

#### 4.1. Conectar na EC2

```bash
ssh -i keypair.pem ec2-user@10.0.0.130
```

#### 4.2. Criar estrutura de diretórios

```bash
sudo mkdir -p /opt/softwave
sudo chown ec2-user:ec2-user /opt/softwave
```

#### 4.3. Copiar docker-compose.prod.yml

```bash
# Via S3 (recomendado)
aws s3 cp s3://softwave-artifacts-prod/docker-compose.prod.yml /opt/softwave/

# OU via scp
scp -i keypair.pem softwave-infra/docker-compose.prod.yml ec2-user@10.0.0.130:/opt/softwave/
```

#### 4.4. Criar arquivo .env

```bash
sudo nano /opt/softwave/.env
```

Conteúdo mínimo (ajuste com valores reais):

```env
# Database
SPRING_DATASOURCE_URL=jdbc:mysql://<RDS_ENDPOINT>:3306/softwave?useSSL=false&serverTimezone=UTC
SPRING_DATASOURCE_USERNAME=admin
SPRING_DATASOURCE_PASSWORD=<SENHA_SEGURA>

# JWT
JWT_SECRET=<SECRET_BASE64_MIN_32_CHARS>
JWT_VALIDITY=3600

# AWS
AWS_ACCESS_KEY=<OU_USAR_IAM_ROLE>
AWS_SECRET_KEY=<OU_USAR_IAM_ROLE>
AWS_REGION=us-east-1
AWS_S3_BUCKET=softwave-arquivos-prod

# Email
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=seu-email@gmail.com
MAIL_PASSWORD=<SENHA_APP>

# CORS
CORS_ALLOWED_ORIGINS=http://<NGINX_ELASTIC_IP>

# RabbitMQ
RABBITMQ_HOST=<RABBITMQ_HOST>
RABBITMQ_PORT=5672
RABBITMQ_USERNAME=<USERNAME>
RABBITMQ_PASSWORD=<PASSWORD>

# File URLs
FILE_BASE_URL=http://<NGINX_ELASTIC_IP>/ArquivosSistemaUsuarios
MICROSERVICE_S3_URL=http://<NGINX_ELASTIC_IP>/api/s3
```

#### 4.5. Copiar systemd service

```bash
sudo cp softwave-infra/systemd/softwave-docker-compose.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable softwave-docker-compose
sudo systemctl start softwave-docker-compose
```

### 5. Verificar Status

```bash
# Status do systemd service
sudo systemctl status softwave-docker-compose

# Status dos containers
docker ps

# Logs do docker-compose
sudo journalctl -u softwave-docker-compose -f

# Logs de um serviço específico
docker logs softwave-backend-1 -f
docker logs softwave-auth-service -f

# Health checks
curl http://localhost:8081/actuator/health
curl http://localhost:8082/actuator/health
curl http://localhost:8083/actuator/health
curl http://localhost:8084/actuator/health
```

## 🔧 Comandos Úteis

### Gerenciar Serviços

```bash
# Iniciar todos os serviços
sudo systemctl start softwave-docker-compose

# Parar todos os serviços
sudo systemctl stop softwave-docker-compose

# Reiniciar todos os serviços
sudo systemctl restart softwave-docker-compose

# Ver logs
sudo journalctl -u softwave-docker-compose -f
```

### Gerenciar Containers Individualmente

```bash
# Via docker-compose (dentro de /opt/softwave)
docker-compose -f docker-compose.prod.yml ps
docker-compose -f docker-compose.prod.yml logs -f backend-1
docker-compose -f docker-compose.prod.yml restart backend-1
docker-compose -f docker-compose.prod.yml up -d backend-1
docker-compose -f docker-compose.prod.yml down
```

### Atualizar Imagem e Redeploy

```bash
# 1. Fazer pull da nova imagem
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
docker pull <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/softwave/backend:latest

# 2. Recriar container específico
cd /opt/softwave
docker-compose -f docker-compose.prod.yml up -d --force-recreate backend-1

# OU recriar todos
docker-compose -f docker-compose.prod.yml up -d --force-recreate
```

## 🐛 Troubleshooting

### Container não inicia

```bash
# Ver logs do container
docker logs softwave-backend-1

# Verificar variáveis de ambiente
docker exec softwave-backend-1 env

# Verificar se porta está em uso
sudo netstat -tlnp | grep 8081
```

### Problemas de permissão Docker

```bash
# Adicionar usuário ao grupo docker (após bootstrap)
sudo usermod -aG docker ec2-user
# Fazer logout e login novamente
newgrp docker
```

### Container reinicia constantemente

```bash
# Ver logs para identificar erro
docker logs softwave-backend-1 --tail 100

# Verificar healthcheck
docker inspect softwave-backend-1 | grep -A 10 Health
```

### Variáveis de ambiente não funcionam

```bash
# Verificar se .env está correto
cat /opt/softwave/.env

# Verificar se systemd está lendo o arquivo
sudo systemctl show softwave-docker-compose | grep EnvironmentFile
```

## 📊 Monitoramento

### Recursos (CPU/Memória)

```bash
docker stats
```

### Logs centralizados

```bash
# Todos os serviços
docker-compose -f docker-compose.prod.yml logs -f

# Serviço específico
docker-compose -f docker-compose.prod.yml logs -f backend-1
```

### Health Checks

```bash
# Verificar health de todos
for port in 8081 8082 8083 8084; do
  echo "Port $port:"
  curl -s http://localhost:$port/actuator/health | jq .
done
```

## 🔒 Segurança

1. **Nunca commite arquivos `.env`** com valores reais
2. **Use IAM Roles** em vez de Access Keys quando possível
3. **Use AWS Secrets Manager** para secrets em produção
4. **Firewall configurado** - portas apenas da VPC
5. **Containers como usuário não-root**

## 📝 Notas

- O systemd service inicia automaticamente após reboot
- Containers têm restart policy `unless-stopped`
- Logs são persistidos em volumes Docker
- Healthchecks verificam automaticamente a saúde dos serviços

