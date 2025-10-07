# SoftWave Infrastructure

Infraestrutura do projeto SoftWave, contendo Docker, Docker Compose, shell scripts e configurações para deploy em ambientes de nuvem (AWS, Azure, GCP).

## 📋 Índice

- [Visão Geral](#visão-geral)
- [Pré-requisitos](#pré-requisitos)
- [Início Rápido](#início-rápido)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Comandos Disponíveis](#comandos-disponíveis)
- [Ambientes de Nuvem](#ambientes-de-nuvem)
- [Desenvolvimento](#desenvolvimento)
- [Variáveis de Ambiente](#variáveis-de-ambiente)

## 🎯 Visão Geral

Este repositório contém toda a infraestrutura necessária para executar o projeto SoftWave, incluindo:

- **Docker**: Containerização da aplicação
- **Docker Compose**: Orquestração de múltiplos serviços (app, PostgreSQL, Redis, Nginx)
- **Shell Scripts**: Automação de inicialização, start e stop
- **Configurações Cloud**: Templates para AWS, Azure e GCP

## 🔧 Pré-requisitos

- [Docker](https://docs.docker.com/get-docker/) (versão 20.10 ou superior)
- [Docker Compose](https://docs.docker.com/compose/install/) (versão 2.0 ou superior)
- Git

Para deploy em nuvem, você também precisará:
- **AWS**: [AWS CLI](https://aws.amazon.com/cli/)
- **Azure**: [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)
- **GCP**: [gcloud CLI](https://cloud.google.com/sdk/docs/install)

## 🚀 Início Rápido

### 1. Clone o repositório

```bash
git clone https://github.com/SoftWave-SPTech/softwave-infra.git
cd softwave-infra
```

### 2. Inicialize o ambiente

```bash
./init.sh
```

Este script irá:
- Verificar se Docker e Docker Compose estão instalados
- Criar diretórios necessários
- Criar arquivo `.env` com valores padrão
- Criar `scripts/init.sql` para inicialização do banco
- Criar configuração do Nginx
- Fazer pull das imagens Docker

### 3. Configure as variáveis de ambiente

Edite o arquivo `.env` gerado com suas configurações:

```bash
nano .env
```

### 4. Inicie os serviços

```bash
./start.sh
```

### 5. Acesse a aplicação

- **Aplicação**: http://localhost:3000
- **Nginx Proxy**: http://localhost:80
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379

## 📁 Estrutura do Projeto

```
softwave-infra/
├── Dockerfile                      # Imagem Docker da aplicação
├── docker-compose.yml              # Orquestração de serviços (produção)
├── docker-compose.dev.yml          # Orquestração para desenvolvimento
├── .env.example                    # Exemplo de variáveis de ambiente
├── .gitignore                      # Arquivos ignorados pelo Git
│
├── init.sh                         # Script de inicialização
├── start.sh                        # Script para iniciar serviços
├── stop.sh                         # Script para parar serviços
│
├── scripts/                        # Scripts SQL e outros
│   └── init.sql                    # Inicialização do banco de dados
│
├── nginx/                          # Configurações do Nginx
│   └── nginx.conf                  # Arquivo de configuração
│
└── cloud/                          # Configurações para nuvem
    ├── aws/                        # Amazon Web Services
    │   ├── cloudformation-template.yml
    │   ├── ecs-task-definition.json
    │   └── deploy.sh
    │
    ├── azure/                      # Microsoft Azure
    │   ├── arm-template.json
    │   ├── container-instance.yaml
    │   └── deploy.sh
    │
    └── gcp/                        # Google Cloud Platform
        ├── cloudrun-service.yaml
        ├── deployment-manager.yaml
        ├── softwave-infrastructure.jinja
        └── deploy.sh
```

## 💻 Comandos Disponíveis

### Scripts Principais

```bash
# Inicializar o ambiente (primeira vez)
./init.sh

# Iniciar todos os serviços em background
./start.sh

# Iniciar serviços em foreground (ver logs)
./start.sh --foreground

# Iniciar com rebuild das imagens
./start.sh --build

# Iniciar apenas serviços específicos
./start.sh app postgres

# Parar todos os serviços
./stop.sh

# Parar e remover volumes
./stop.sh --volumes

# Parar, remover volumes e imagens
./stop.sh --all
```

### Docker Compose

```bash
# Ver logs de todos os serviços
docker compose logs -f

# Ver logs de um serviço específico
docker compose logs -f app

# Ver status dos serviços
docker compose ps

# Executar comando em um container
docker compose exec app sh

# Acessar banco de dados
docker compose exec postgres psql -U softwave_user -d softwave

# Rebuild de um serviço específico
docker compose up -d --build app
```

## ☁️ Ambientes de Nuvem

### AWS (Amazon Web Services)

Deploy usando ECS (Elastic Container Service):

```bash
cd cloud/aws

# Configure as variáveis de ambiente
export AWS_REGION=us-east-1
export ECR_REPOSITORY=softwave
export ECS_CLUSTER=softwave-cluster

# Execute o deploy
./deploy.sh
```

Ou use CloudFormation para criar toda a infraestrutura:

```bash
aws cloudformation create-stack \
  --stack-name softwave-infrastructure \
  --template-body file://cloudformation-template.yml \
  --parameters ParameterKey=DBPassword,ParameterValue=YourSecurePassword123
```

### Azure

Deploy usando Azure Container Instances ou App Service:

```bash
cd cloud/azure

# Configure as variáveis
export RESOURCE_GROUP=softwave-rg
export LOCATION=eastus
export ACR_NAME=softwaveacr

# Execute o deploy
./deploy.sh
```

Ou use ARM Template:

```bash
az deployment group create \
  --resource-group softwave-rg \
  --template-file arm-template.json \
  --parameters administratorLoginPassword="YourSecurePassword123"
```

### GCP (Google Cloud Platform)

Deploy usando Cloud Run:

```bash
cd cloud/gcp

# Configure as variáveis
export GCP_PROJECT_ID=your-project-id
export GCP_REGION=us-central1

# Execute o deploy
./deploy.sh
```

Ou use Deployment Manager:

```bash
gcloud deployment-manager deployments create softwave \
  --config deployment-manager.yaml
```

## 🔨 Desenvolvimento

Para desenvolvimento local com hot-reload:

```bash
# Use o docker-compose de desenvolvimento
docker compose -f docker-compose.dev.yml up

# Acesse as ferramentas de desenvolvimento:
# - PgAdmin: http://localhost:5050 (admin@softwave.com / admin)
# - Redis Commander: http://localhost:8081
```

## 🔐 Variáveis de Ambiente

Principais variáveis de ambiente (veja `.env.example` para lista completa):

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `NODE_ENV` | Ambiente de execução | `development` |
| `APP_PORT` | Porta da aplicação | `3000` |
| `DB_HOST` | Host do PostgreSQL | `postgres` |
| `DB_PORT` | Porta do PostgreSQL | `5432` |
| `DB_NAME` | Nome do banco de dados | `softwave` |
| `DB_USER` | Usuário do banco | `softwave_user` |
| `DB_PASSWORD` | Senha do banco | `softwave_pass` |
| `REDIS_HOST` | Host do Redis | `redis` |
| `REDIS_PORT` | Porta do Redis | `6379` |
| `JWT_SECRET` | Secret para JWT | - |

**⚠️ IMPORTANTE**: Altere as senhas e secrets padrão em ambientes de produção!

## 📝 Notas

- **Segurança**: Nunca commite arquivos `.env` com credenciais reais
- **Produção**: Revise e ajuste as configurações de recursos (CPU, memória) para produção
- **Backup**: Configure backups automáticos para os bancos de dados em produção
- **Monitoramento**: Considere adicionar ferramentas de monitoramento (Prometheus, Grafana, etc.)
- **SSL/TLS**: Configure certificados SSL para ambientes de produção

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto é parte do SoftWave e está sob a licença [inserir licença aqui].

## 📧 Contato

SoftWave Team - [@SoftWave-SPTech](https://github.com/SoftWave-SPTech)
