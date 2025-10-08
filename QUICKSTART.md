# Quick Start Guide

Este guia rápido ajudará você a começar com o SoftWave Infrastructure em minutos.

## 📦 Pré-requisitos Rápidos

Antes de começar, certifique-se de ter instalado:

```bash
# Verificar se Docker está instalado
docker --version

# Verificar se Docker Compose está instalado
docker compose version
```

Se não tiver instalado, visite:
- Docker: https://docs.docker.com/get-docker/
- Docker Compose: https://docs.docker.com/compose/install/

## 🚀 5 Passos para Começar

### Passo 1: Clone o Repositório

```bash
git clone https://github.com/SoftWave-SPTech/softwave-infra.git
cd softwave-infra
```

### Passo 2: Inicialize o Ambiente

```bash
./init.sh
```

Este comando irá:
- ✓ Verificar instalação do Docker
- ✓ Criar diretórios necessários
- ✓ Gerar arquivo `.env` com configurações padrão
- ✓ Criar script de inicialização do banco de dados
- ✓ Configurar o Nginx
- ✓ Fazer download das imagens Docker

### Passo 3: Configure as Variáveis (Opcional)

Para desenvolvimento local, as configurações padrão funcionam. Para produção:

```bash
nano .env
```

Altere especialmente:
- `DB_PASSWORD` - Senha do banco de dados
- `JWT_SECRET` - Secret para autenticação
- `API_KEY` - Chave de API

### Passo 4: Inicie os Serviços

```bash
./start.sh
```

Aguarde alguns segundos para os serviços iniciarem.

### Passo 5: Acesse a Aplicação

- **Aplicação**: http://localhost:3000
- **Proxy Nginx**: http://localhost:80
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379

## 📋 Comandos Úteis

```bash
# Ver logs em tempo real
docker compose logs -f

# Ver logs apenas da aplicação
docker compose logs -f app

# Verificar status dos containers
docker compose ps

# Parar todos os serviços
./stop.sh

# Reiniciar serviços
./stop.sh && ./start.sh
```

## 🔧 Usando Makefile (Atalhos)

Se preferir usar `make`:

```bash
# Ver todos os comandos disponíveis
make help

# Inicializar
make init

# Iniciar serviços
make start

# Ver logs
make logs

# Parar serviços
make stop

# Abrir shell no container
make shell

# Acessar PostgreSQL
make db-shell

# Acessar Redis CLI
make redis-cli
```

## 🐛 Problemas Comuns

### Docker não está rodando

```bash
# Linux
sudo systemctl start docker

# macOS/Windows
# Inicie o Docker Desktop
```

### Porta já em uso

Se a porta 3000, 5432 ou 6379 já estiver em uso:

```bash
# Edite docker-compose.yml e altere as portas
# Por exemplo, mudar "3000:3000" para "3001:3000"
```

### Permissão negada ao executar scripts

```bash
# Torne os scripts executáveis
chmod +x *.sh cloud/*/*.sh
```

### Containers não iniciam

```bash
# Limpe tudo e recomece
./stop.sh --all
./init.sh
./start.sh
```

## 🧪 Modo Desenvolvimento

Para desenvolvimento com hot-reload e ferramentas de admin:

```bash
# Use o docker-compose de desenvolvimento
docker compose -f docker-compose.dev.yml up

# Ou use o makefile
make dev
```

Ferramentas disponíveis:
- **PgAdmin**: http://localhost:5050 (admin@softwave.com / admin)
- **Redis Commander**: http://localhost:8081

## 📊 Verificação de Saúde

```bash
# Verificar se a aplicação está respondendo
curl http://localhost:3000/health

# Verificar PostgreSQL
docker compose exec postgres pg_isready -U softwave_user

# Verificar Redis
docker compose exec redis redis-cli ping
```

## 💾 Backup Rápido

```bash
# Criar backup
./backup.sh

# Backups são salvos em ./backups/
```

## ☁️ Deploy em Nuvem

Para fazer deploy em nuvem, veja o guia detalhado:

```bash
# AWS
cd cloud/aws
./deploy.sh

# Azure
cd cloud/azure
./deploy.sh

# GCP
cd cloud/gcp
./deploy.sh
```

Mais detalhes em: [cloud/README.md](cloud/README.md)

## 📚 Próximos Passos

1. **Personalize a aplicação**: Edite o `Dockerfile` para sua aplicação específica
2. **Configure o banco**: Adicione suas tabelas em `scripts/init.sql`
3. **Ajuste o Nginx**: Modifique `nginx/nginx.conf` conforme necessário
4. **Prepare para produção**: Revise as configurações de segurança em `.env`
5. **Configure CI/CD**: Adicione workflows do GitHub Actions

## 🆘 Precisa de Ajuda?

- 📖 Leia o [README.md](README.md) completo
- ☁️ Consulte o [guia de cloud](cloud/README.md)
- 🐛 Reporte issues no [GitHub](https://github.com/SoftWave-SPTech/softwave-infra/issues)

## 🎉 Pronto!

Agora você tem um ambiente completo rodando com:
- ✓ Aplicação containerizada
- ✓ Banco de dados PostgreSQL
- ✓ Cache Redis
- ✓ Proxy Nginx
- ✓ Scripts de gerenciamento
- ✓ Configurações de cloud prontas

Comece a desenvolver! 🚀
