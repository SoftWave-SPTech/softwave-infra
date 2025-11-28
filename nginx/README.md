# 🌐 Configuração NGINX para SoftWave

Este diretório contém as configurações do NGINX para fazer proxy reverso e balanceamento de carga dos serviços backend.

## 📁 Arquivos

- **`nginx.conf`** - Configuração para arquitetura distribuída (serviços em EC2s diferentes)
- **`nginx.conf.docker`** - Configuração para serviços na mesma EC2 via Docker Compose

## 🏗️ Arquiteturas Suportadas

### Opção 1: Serviços em EC2s Diferentes (nginx.conf)

```
NGINX (10.0.0.x - Pública)
    ├── Backend-1 (10.0.0.130:8081)
    ├── Backend-2 (10.0.0.131:8082)
    ├── Auth Service (10.0.0.130:8083)
    ├── S3 Service (10.0.0.130:8081)
    ├── Gemini Service (10.0.0.131:8082)
    └── Consultas Service (10.0.0.130:8084)
```

**Uso:** Quando cada serviço roda em EC2s separadas ou distribuições específicas.

### Opção 2: Todos os Serviços na Mesma EC2 (nginx.conf.docker)

```
NGINX (10.0.0.x - Pública)
    └── EC2 Backend (10.0.0.130)
        ├── Backend-1 (localhost:8081) - Docker
        ├── Backend-2 (localhost:8082) - Docker
        ├── Auth Service (localhost:8083) - Docker
        ├── S3 Service (localhost:8081) - Docker
        ├── Gemini Service (localhost:8082) - Docker
        └── Consultas Service (localhost:8084) - Docker
```

**Uso:** Quando todos os serviços rodam via Docker Compose na mesma EC2.

## 🚀 Como Usar

### 1. Escolher a configuração apropriada

```bash
# Para arquitetura distribuída (EC2s diferentes)
sudo cp softwave-infra/nginx/nginx.conf /etc/nginx/nginx.conf

# OU para Docker Compose (mesma EC2)
sudo cp softwave-infra/nginx/nginx.conf.docker /etc/nginx/nginx.conf
```

### 2. Ajustar IPs conforme necessário

Edite o arquivo e ajuste os IPs nos upstreams:

```nginx
upstream backend_apis {
    server 10.0.0.130:8081;  # Ajuste se necessário
    server 10.0.0.131:8082;  # Ajuste se necessário
}
```

### 3. Testar configuração

```bash
sudo nginx -t
```

### 4. Aplicar configuração

```bash
sudo systemctl reload nginx
# OU
sudo systemctl restart nginx
```

## 📋 Roteamento de APIs

| Path NGINX | Upstream | Descrição |
|------------|----------|-----------|
| `/api/*` | `backend_apis` | Backend principal (balanceamento) |
| `/api/s3/*` | `s3_service` | Upload/download S3 |
| `/api/auth/*` | `auth_service` | Autenticação e email |
| `/api/gemini/*` | `gemini_service` | Integração com Gemini AI |
| `/api/consultas/*` | `consultas_service` | Consultas externas |

## 🔧 Configurações Importantes

### Balanceamento

- **Método:** `least_conn` (menor conexão)
- **Health Check:** `max_fails=3 fail_timeout=30s`
- **Keepalive:** 32 conexões

### Timeouts

- **Proxy Read:** 300s (600s para Gemini e S3)
- **Proxy Connect:** 75s
- **Keepalive:** 65s

### Upload de Arquivos

- **Max Body Size:** 25M (global), 10M (S3 service)

### Cache

- **Assets estáticos:** 1 ano de cache
- **Headers:** `Cache-Control: public, immutable`

## 🐛 Troubleshooting

### Verificar se NGINX está rodando

```bash
sudo systemctl status nginx
```

### Ver logs de erro

```bash
sudo tail -f /var/log/nginx/error.log
```

### Ver logs de acesso

```bash
sudo tail -f /var/log/nginx/access.log
```

### Testar conectividade com backends

```bash
# Da EC2 NGINX, testar backends
curl -v http://10.0.0.130:8081/actuator/health
curl -v http://10.0.0.131:8082/actuator/health
```

### Verificar se portas estão abertas

```bash
sudo netstat -tlnp | grep nginx
```

### Recarregar configuração sem downtime

```bash
sudo nginx -t && sudo systemctl reload nginx
```

## 📝 Notas

- NGINX roda na **sub-rede pública** (10.0.0.0/25)
- Backends rodam na **sub-rede privada** (10.0.0.128/25)
- Security Groups devem permitir tráfego apenas da VPC
- Para HTTPS, adicione configuração SSL/TLS (certificado ACM)

## 🔒 Segurança

- Actuator endpoints bloqueados para IPs externos
- Headers de segurança adicionados
- Acesso a arquivos `.` negado
- Timeouts configurados para prevenir DoS

