# SoftWave Infraestrutura - Deploy e Configuração

Configurações de infraestrutura, Docker, Nginx e deploy em produção para o sistema SoftWave.

## Tecnologias Utilizadas

![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![Nginx](https://img.shields.io/badge/nginx-%23009639.svg?style=for-the-badge&logo=nginx&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Shell Script](https://img.shields.io/badge/shell_script-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)

### Componentes

- **Docker & Docker Compose** - Containerização
- **Nginx** - Proxy reverso e load balancer
- **AWS EC2** - Hospedagem em nuvem
- **Systemd** - Gerenciamento de serviços
- **Shell Scripts** - Automação de deploy

## Estrutura do Projeto

```
softwave-infra/
├── docker/
│   ├── Dockerfile.backend      # Dockerfile backend
│   └── Dockerfile.generic      # Dockerfile genérico
├── nginx/
│   ├── nginx.conf             # Configuração local
│   ├── nginx.conf.docker      # Configuração Docker
│   └── README.md              # Documentação Nginx
├── scripts/
│   ├── aws-setup-account.sh   # Setup inicial AWS
│   ├── bootstrap-backend.sh   # Deploy backend
│   ├── bootstrap-nginx.sh     # Setup Nginx
│   ├── build-all-images.sh    # Build todas imagens
│   ├── build-and-push.sh      # Build e push Docker Hub
│   ├── ec2-bootstrap-and-deploy.sh  # Deploy EC2 completo
│   └── upload-config-to-s3.sh # Upload configs para S3
├── systemd/
│   └── softwave-docker-compose.service  # Serviço systemd
├── docker-compose.prod.yml    # Compose produção
└── README.md
```

## Configuração de Produção

### Docker Compose Produção

O arquivo `docker-compose.prod.yml` orquestra todos os microserviços:

```yaml
# Serviços configurados:
# - backend-1 (porta 8081)
# - backend-2 (porta 8082) - Load balancing
# - auth-service (porta 8083)
# - s3-service (porta 8091)
# - gemini-service (porta 8092)
# - consultas-service (porta 8084)
```

### Variáveis de Ambiente Necessárias

```bash
# Database
SPRING_DATASOURCE_URL=jdbc:mysql://host:3306/softwave_db
SPRING_DATASOURCE_USERNAME=softwave
SPRING_DATASOURCE_PASSWORD=senha-segura

# JWT
JWT_SECRET=seu-jwt-secret-super-seguro
JWT_VALIDITY=3600

# AWS
AWS_ACCESS_KEY=sua-access-key
AWS_SECRET_KEY=sua-secret-key
AWS_REGION=us-east-1
AWS_S3_BUCKET=softwave-arquivos-prod

# Email
MAIL_HOST=smtp.gmail.com
MAIL_USERNAME=seu-email@gmail.com
MAIL_PASSWORD=sua-senha-app

# RabbitMQ
RABBITMQ_HOST=seu-rabbitmq-host
RABBITMQ_USERNAME=softwave
RABBITMQ_PASSWORD=senha-rabbitmq

# CORS
CORS_ALLOWED_ORIGINS=https://seu-dominio.com
```

### Configuração Nginx

O Nginx atua como proxy reverso e load balancer:

```nginx
# Load balancing para backend principal
upstream backend_pool {
    server backend-1:8081;
    server backend-2:8082;
}

# Proxy para microserviços específicos
location /auth/ {
    proxy_pass http://auth-service:8083/;
}

location /s3/ {
    proxy_pass http://s3-service:8091/;
}
```

## Deploy AWS EC2

### 1. Configuração Inicial

```bash
# Executar script de setup
./scripts/aws-setup-account.sh

# Configurar credenciais AWS
aws configure
```

### 2. Deploy Completo

```bash
# Script completo de deploy
./scripts/ec2-bootstrap-and-deploy.sh

# Ou passos individuais:
./scripts/build-all-images.sh
./scripts/build-and-push.sh
./scripts/bootstrap-nginx.sh
./scripts/bootstrap-backend.sh
```

### 3. Configuração do Serviço Systemd

```bash
# Copiar arquivo de serviço
sudo cp systemd/softwave-docker-compose.service /etc/systemd/system/

# Habilitar e iniciar serviço
sudo systemctl enable softwave-docker-compose
sudo systemctl start softwave-docker-compose

# Verificar status
sudo systemctl status softwave-docker-compose
```

## Monitoramento

### Health Checks

Todos os serviços possuem health checks configurados:

```bash
# Verificar status dos containers
docker-compose -f docker-compose.prod.yml ps

# Logs dos serviços
docker-compose -f docker-compose.prod.yml logs backend-1
docker-compose -f docker-compose.prod.yml logs nginx
```

### Métricas

```bash
# CPU e memória dos containers
docker stats

# Logs do sistema
journalctl -u softwave-docker-compose -f
```

## SSL/TLS

### Certificado Let's Encrypt

```bash
# Instalar Certbot
sudo apt install certbot python3-certbot-nginx

# Obter certificado
sudo certbot --nginx -d seu-dominio.com

# Renovação automática
sudo systemctl enable certbot.timer
```

## Troubleshooting

### Problemas Comuns

1. **Container não inicia**: Verificar logs e variáveis de ambiente
2. **Nginx 502**: Verificar se backend está rodando
3. **SSL não funciona**: Verificar certificados e configuração
4. **Performance ruim**: Verificar recursos EC2 e otimizar

### Comandos Úteis

```bash
# Reiniciar todos os serviços
sudo systemctl restart softwave-docker-compose

# Ver logs em tempo real
docker-compose -f docker-compose.prod.yml logs -f

# Verificar conectividade entre containers
docker exec backend-1 ping auth-service
```

## Atualizações

### Deploy de Nova Versão

```bash
# 1. Fazer pull das novas imagens
docker-compose -f docker-compose.prod.yml pull

# 2. Parar serviços
docker-compose -f docker-compose.prod.yml down

# 3. Iniciar com novas imagens
docker-compose -f docker-compose.prod.yml up -d

# 4. Verificar saúde dos serviços
./scripts/health-check.sh
```

## Contribuição

1. Teste mudanças localmente primeiro
2. Use scripts de automação para deploy
3. Monitore logs após deploy
4. Mantenha backups atualizados

## Licença

Este projeto é propriedade da SoftWave SPTech e destina-se ao uso exclusivo do escritório Lauriano & Leão Sociedade de Advogados.

---

**Desenvolvido por:** SoftWave SPTech  
**Data:** 2025
