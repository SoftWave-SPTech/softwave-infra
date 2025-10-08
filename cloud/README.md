# Cloud Deployment Guide

Este diretório contém configurações e scripts para deploy do SoftWave em diferentes provedores de nuvem.

## Índice

- [AWS (Amazon Web Services)](#aws)
- [Azure (Microsoft Azure)](#azure)
- [GCP (Google Cloud Platform)](#gcp)
- [Comparação de Serviços](#comparação-de-serviços)
- [Melhores Práticas](#melhores-práticas)

## AWS

### Serviços Utilizados

- **ECS (Elastic Container Service)**: Para executar containers
- **ECR (Elastic Container Registry)**: Para armazenar imagens Docker
- **RDS (Relational Database Service)**: PostgreSQL gerenciado
- **ElastiCache**: Redis gerenciado
- **VPC**: Rede privada virtual
- **CloudFormation**: Infraestrutura como código

### Deploy Rápido

```bash
cd aws

# Configure credenciais AWS
aws configure

# Execute o deploy
./deploy.sh
```

### Deploy com CloudFormation

```bash
# Criar stack completa
aws cloudformation create-stack \
  --stack-name softwave-prod \
  --template-body file://cloudformation-template.yml \
  --parameters ParameterKey=DBPassword,ParameterValue=SecurePassword123 \
  --capabilities CAPABILITY_IAM

# Verificar status
aws cloudformation describe-stacks --stack-name softwave-prod

# Atualizar stack
aws cloudformation update-stack \
  --stack-name softwave-prod \
  --template-body file://cloudformation-template.yml

# Deletar stack
aws cloudformation delete-stack --stack-name softwave-prod
```

### Custos Estimados (us-east-1)

- ECS Fargate (0.5 vCPU, 1GB): ~$15/mês
- RDS PostgreSQL (db.t3.micro): ~$15/mês
- ElastiCache Redis (cache.t3.micro): ~$12/mês
- **Total aproximado**: ~$42/mês

## Azure

### Serviços Utilizados

- **Container Instances / App Service**: Para executar containers
- **Container Registry (ACR)**: Para armazenar imagens Docker
- **Azure Database for PostgreSQL**: PostgreSQL gerenciado
- **Azure Cache for Redis**: Redis gerenciado
- **Virtual Network**: Rede privada virtual
- **ARM Templates**: Infraestrutura como código

### Deploy Rápido

```bash
cd azure

# Login no Azure
az login

# Execute o deploy
./deploy.sh
```

### Deploy com ARM Template

```bash
# Criar resource group
az group create --name softwave-rg --location eastus

# Deploy usando template
az deployment group create \
  --resource-group softwave-rg \
  --template-file arm-template.json \
  --parameters administratorLoginPassword="SecurePassword123"

# Verificar recursos
az resource list --resource-group softwave-rg --output table

# Deletar resource group
az group delete --name softwave-rg --yes
```

### Custos Estimados (East US)

- App Service (B1): ~$13/mês
- Azure Database for PostgreSQL (B1ms): ~$16/mês
- Azure Cache for Redis (Basic C0): ~$16/mês
- **Total aproximado**: ~$45/mês

## GCP

### Serviços Utilizados

- **Cloud Run**: Para executar containers serverless
- **Container Registry (GCR)**: Para armazenar imagens Docker
- **Cloud SQL**: PostgreSQL gerenciado
- **Memorystore**: Redis gerenciado
- **VPC Network**: Rede privada virtual
- **Deployment Manager**: Infraestrutura como código

### Deploy Rápido

```bash
cd gcp

# Login no GCP
gcloud auth login

# Configure o projeto
gcloud config set project YOUR_PROJECT_ID

# Execute o deploy
./deploy.sh
```

### Deploy com Deployment Manager

```bash
# Criar deployment
gcloud deployment-manager deployments create softwave \
  --config deployment-manager.yaml

# Verificar status
gcloud deployment-manager deployments describe softwave

# Atualizar deployment
gcloud deployment-manager deployments update softwave \
  --config deployment-manager.yaml

# Deletar deployment
gcloud deployment-manager deployments delete softwave
```

### Deploy Cloud Run Manual

```bash
# Build e push da imagem
gcloud builds submit --tag gcr.io/PROJECT_ID/softwave

# Deploy no Cloud Run
gcloud run deploy softwave-app \
  --image gcr.io/PROJECT_ID/softwave \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 3000
```

### Custos Estimados (us-central1)

- Cloud Run (1 vCPU, 512MB, sempre 1 instância): ~$12/mês
- Cloud SQL (db-f1-micro): ~$15/mês
- Memorystore Redis (1GB Basic): ~$35/mês
- **Total aproximado**: ~$62/mês

## Comparação de Serviços

| Recurso | AWS | Azure | GCP |
|---------|-----|-------|-----|
| **Container Runtime** | ECS/Fargate | Container Instances/App Service | Cloud Run |
| **Container Registry** | ECR | ACR | GCR/Artifact Registry |
| **PostgreSQL** | RDS | Azure Database | Cloud SQL |
| **Redis** | ElastiCache | Azure Cache | Memorystore |
| **IaC Tool** | CloudFormation | ARM Templates | Deployment Manager |
| **CLI** | aws-cli | azure-cli | gcloud |
| **Custo Aproximado/Mês** | $42 | $45 | $62 |
| **Free Tier** | ✓ (12 meses) | ✓ (12 meses) | ✓ (sempre) |

## Melhores Práticas

### Segurança

1. **Secrets Management**
   - AWS: Use AWS Secrets Manager
   - Azure: Use Azure Key Vault
   - GCP: Use Secret Manager

2. **Networking**
   - Use VPCs/VNets privadas
   - Restrinja acesso ao banco apenas para a aplicação
   - Use SSL/TLS para todas as conexões

3. **IAM**
   - Siga o princípio do menor privilégio
   - Use roles específicas para cada serviço
   - Rotacione credenciais regularmente

### Performance

1. **Caching**
   - Utilize Redis para cache de sessões e dados frequentes
   - Configure TTL apropriado para cada tipo de dado

2. **Database**
   - Use connection pooling
   - Configure índices adequados
   - Monitore queries lentas

3. **Scaling**
   - Configure auto-scaling baseado em CPU/memória
   - Use load balancers para distribuir tráfego

### Custos

1. **Otimização**
   - Use instâncias spot/preemptible quando possível
   - Configure auto-scaling para reduzir durante baixa demanda
   - Use reserved instances para cargas previsíveis

2. **Monitoramento**
   - Configure alertas de custo
   - Revise uso mensalmente
   - Remova recursos não utilizados

### Backup e Disaster Recovery

1. **Backups Automáticos**
   - Configure backups diários para bancos de dados
   - Mantenha backups por pelo menos 7 dias
   - Teste restauração regularmente

2. **High Availability**
   - Use multi-AZ/região quando necessário
   - Configure replicação para bancos críticos
   - Implemente health checks

### Monitoramento

1. **Logs**
   - Centralize logs em um único lugar
   - Configure retenção apropriada
   - Use log aggregation (CloudWatch, Azure Monitor, Cloud Logging)

2. **Métricas**
   - Monitore CPU, memória, disco
   - Configure alertas para anomalias
   - Acompanhe latência e taxa de erro

3. **APM (Application Performance Monitoring)**
   - Considere usar New Relic, Datadog, ou similar
   - Monitore transações e queries
   - Identifique gargalos

## Variáveis de Ambiente por Cloud

### AWS

```bash
# Deployment
export AWS_REGION=us-east-1
export ECR_REPOSITORY=softwave
export ECS_CLUSTER=softwave-cluster
export ECS_SERVICE=softwave-service

# Application
export DB_HOST=softwave-db.xxx.rds.amazonaws.com
export REDIS_HOST=softwave-redis.xxx.cache.amazonaws.com
```

### Azure

```bash
# Deployment
export RESOURCE_GROUP=softwave-rg
export LOCATION=eastus
export ACR_NAME=softwaveacr
export APP_NAME=softwave-app

# Application
export DB_HOST=softwave-db.postgres.database.azure.com
export REDIS_HOST=softwave-redis.redis.cache.windows.net
```

### GCP

```bash
# Deployment
export GCP_PROJECT_ID=your-project-id
export GCP_REGION=us-central1
export SERVICE_NAME=softwave-app

# Application
export DB_HOST=/cloudsql/PROJECT_ID:REGION:softwave-db
export REDIS_HOST=10.0.0.3  # Internal IP
```

## Troubleshooting

### AWS

```bash
# Ver logs do ECS
aws logs tail /ecs/softwave-app --follow

# Verificar status do serviço
aws ecs describe-services --cluster softwave-cluster --services softwave-service

# Ver tarefas em execução
aws ecs list-tasks --cluster softwave-cluster
```

### Azure

```bash
# Ver logs do container
az container logs --resource-group softwave-rg --name softwave-app

# Ver logs do App Service
az webapp log tail --resource-group softwave-rg --name softwave-app

# Verificar status
az resource list --resource-group softwave-rg --output table
```

### GCP

```bash
# Ver logs do Cloud Run
gcloud run services logs read softwave-app --limit 100

# Verificar status do serviço
gcloud run services describe softwave-app --region us-central1

# Ver revisões
gcloud run revisions list --service softwave-app --region us-central1
```

## Suporte

Para problemas específicos de cloud:
- AWS: [AWS Support](https://aws.amazon.com/support/)
- Azure: [Azure Support](https://azure.microsoft.com/support/)
- GCP: [Google Cloud Support](https://cloud.google.com/support)

Para problemas com a aplicação:
- Abra uma issue no [repositório do GitHub](https://github.com/SoftWave-SPTech/softwave-infra/issues)
