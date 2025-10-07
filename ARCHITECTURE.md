# SoftWave Infrastructure Architecture

## Overview

Este documento descreve a arquitetura da infraestrutura do projeto SoftWave.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                           SoftWave Infrastructure                    │
└─────────────────────────────────────────────────────────────────────┘

                          ┌──────────────┐
                          │    Client    │
                          │  (Browser)   │
                          └──────┬───────┘
                                 │
                                 │ HTTP/HTTPS
                                 ▼
┌────────────────────────────────────────────────────────────────────┐
│                         Docker Network                              │
│                     (softwave-network)                              │
│                                                                      │
│  ┌────────────────┐                                                │
│  │     Nginx      │                                                │
│  │  Reverse Proxy │                                                │
│  │    Port 80     │                                                │
│  └────────┬───────┘                                                │
│           │                                                         │
│           │ Forward to                                             │
│           ▼                                                         │
│  ┌────────────────┐      ┌────────────────┐  ┌────────────────┐  │
│  │   SoftWave     │─────▶│   PostgreSQL   │  │     Redis      │  │
│  │   Application  │      │    Database    │  │     Cache      │  │
│  │   Port 3000    │◀─────│    Port 5432   │  │   Port 6379    │  │
│  └────────────────┘      └────────────────┘  └────────────────┘  │
│                                                                      │
│  ┌────────────────┐      ┌────────────────┐                       │
│  │  Volume:       │      │  Volume:       │                       │
│  │  postgres-data │      │  redis-data    │                       │
│  └────────────────┘      └────────────────┘                       │
└────────────────────────────────────────────────────────────────────┘

                          ┌──────────────┐
                          │ Host Machine │
                          └──────────────┘
                          • Port 80 → Nginx
                          • Port 3000 → App
                          • Port 5432 → PostgreSQL
                          • Port 6379 → Redis
```

## Components

### 1. Application Container

**Image:** Custom Node.js application (built from Dockerfile)
**Purpose:** Run the main SoftWave application
**Key Features:**
- Multi-stage build for optimized image size
- Non-root user for security
- Health checks for reliability
- Auto-restart on failure

**Environment Variables:**
- `NODE_ENV`: Application environment
- `DB_HOST`, `DB_PORT`, `DB_NAME`: Database connection
- `REDIS_HOST`, `REDIS_PORT`: Cache connection

### 2. PostgreSQL Database

**Image:** postgres:15-alpine
**Purpose:** Relational database for persistent storage
**Key Features:**
- Alpine-based for smaller size
- Automatic initialization with init.sql
- Health checks
- Persistent volume storage

**Volumes:**
- `postgres-data`: Database files
- `./scripts/init.sql`: Initialization script

### 3. Redis Cache

**Image:** redis:7-alpine
**Purpose:** In-memory cache and session storage
**Key Features:**
- Append-only file (AOF) persistence
- Health checks
- Persistent volume storage

**Volumes:**
- `redis-data`: Redis persistence files

### 4. Nginx Reverse Proxy

**Image:** nginx:alpine
**Purpose:** Load balancing, SSL termination, static file serving
**Key Features:**
- Lightweight Alpine-based
- Configurable proxy settings
- SSL/TLS support ready

**Configuration:**
- Custom nginx.conf
- SSL certificates support

## Network Architecture

### Docker Network

All services communicate through a bridge network named `softwave-network`.

**Benefits:**
- Service isolation
- DNS-based service discovery
- Internal communication without exposing ports

**Service DNS Names:**
- `app` → Application container
- `postgres` → Database container
- `redis` → Cache container
- `nginx` → Reverse proxy

## Data Flow

### Request Flow

```
1. Client → Nginx (Port 80)
2. Nginx → App (Port 3000)
3. App → PostgreSQL (Port 5432) [if needed]
4. App → Redis (Port 6379) [if needed]
5. App → Nginx
6. Nginx → Client
```

### Database Initialization Flow

```
1. Docker Compose starts PostgreSQL
2. PostgreSQL executes /docker-entrypoint-initdb.d/init.sql
3. Database schema and initial data created
4. Application connects to ready database
```

## Storage Architecture

### Volumes

**Named Volumes (Docker Managed):**
- `postgres-data`: Database files (persistent across restarts)
- `redis-data`: Redis snapshots (persistent across restarts)

**Bind Mounts:**
- `./logs`: Application logs (host machine)
- `./scripts/init.sql`: DB initialization (host machine)
- `./nginx/nginx.conf`: Nginx config (host machine)

### Backup Strategy

```
┌──────────────┐
│   Backup     │
│   Script     │
└──────┬───────┘
       │
       ├─────▶ PostgreSQL Dump (.sql.gz)
       │       • Daily backups
       │       • 7-day retention
       │
       └─────▶ Redis Snapshot (.rdb.gz)
               • Daily backups
               • 7-day retention
```

## Cloud Architecture

### AWS Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS Cloud                             │
│                                                               │
│  ┌──────────────┐        ┌─────────────────┐               │
│  │  Application │        │   VPC           │               │
│  │  Load        │───────▶│                 │               │
│  │  Balancer    │        │  ┌───────────┐  │               │
│  └──────────────┘        │  │    ECS    │  │               │
│                           │  │  Cluster  │  │               │
│                           │  │           │  │               │
│                           │  │  Fargate  │  │               │
│                           │  │   Tasks   │  │               │
│                           │  └─────┬─────┘  │               │
│                           │        │        │               │
│                           │        ▼        │               │
│  ┌──────────────┐        │  ┌───────────┐  │               │
│  │     RDS      │◀───────┼──│ Security  │  │               │
│  │  PostgreSQL  │        │  │  Groups   │  │               │
│  └──────────────┘        │  └─────┬─────┘  │               │
│                           │        │        │               │
│  ┌──────────────┐        │        ▼        │               │
│  │ ElastiCache  │◀───────┼──────────────── │               │
│  │    Redis     │        │                 │               │
│  └──────────────┘        └─────────────────┘               │
│                                                               │
│  ┌──────────────┐        ┌─────────────────┐               │
│  │     ECR      │        │   Secrets       │               │
│  │  Container   │        │   Manager       │               │
│  │  Registry    │        │                 │               │
│  └──────────────┘        └─────────────────┘               │
└─────────────────────────────────────────────────────────────┘
```

### Azure Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Azure Cloud                             │
│                                                               │
│  ┌──────────────┐        ┌─────────────────┐               │
│  │  Application │        │  Virtual        │               │
│  │  Gateway     │───────▶│  Network        │               │
│  └──────────────┘        │                 │               │
│                           │  ┌───────────┐  │               │
│                           │  │   App     │  │               │
│                           │  │  Service  │  │               │
│                           │  │           │  │               │
│                           │  │Container  │  │               │
│                           │  │Instances  │  │               │
│                           │  └─────┬─────┘  │               │
│                           │        │        │               │
│  ┌──────────────┐        │        ▼        │               │
│  │   Azure DB   │◀───────┼──  NSG Rules    │               │
│  │ for PostgreSQL        │                 │               │
│  └──────────────┘        │                 │               │
│                           │                 │               │
│  ┌──────────────┐        │                 │               │
│  │  Azure Cache │◀───────┼─────────────────│               │
│  │  for Redis   │        │                 │               │
│  └──────────────┘        └─────────────────┘               │
│                                                               │
│  ┌──────────────┐        ┌─────────────────┐               │
│  │   Azure      │        │   Key Vault     │               │
│  │  Container   │        │                 │               │
│  │  Registry    │        │                 │               │
│  └──────────────┘        └─────────────────┘               │
└─────────────────────────────────────────────────────────────┘
```

### GCP Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Google Cloud                             │
│                                                               │
│  ┌──────────────┐        ┌─────────────────┐               │
│  │  Cloud Load  │        │   VPC           │               │
│  │  Balancer    │───────▶│   Network       │               │
│  └──────────────┘        │                 │               │
│                           │  ┌───────────┐  │               │
│                           │  │   Cloud   │  │               │
│                           │  │    Run    │  │               │
│                           │  │           │  │               │
│                           │  │Serverless │  │               │
│                           │  │Containers │  │               │
│                           │  └─────┬─────┘  │               │
│                           │        │        │               │
│  ┌──────────────┐        │        ▼        │               │
│  │  Cloud SQL   │◀───────┼──  Firewall     │               │
│  │  PostgreSQL  │        │    Rules        │               │
│  └──────────────┘        │                 │               │
│                           │                 │               │
│  ┌──────────────┐        │                 │               │
│  │ Memorystore  │◀───────┼─────────────────│               │
│  │    Redis     │        │                 │               │
│  └──────────────┘        └─────────────────┘               │
│                                                               │
│  ┌──────────────┐        ┌─────────────────┐               │
│  │   Container  │        │   Secret        │               │
│  │   Registry   │        │   Manager       │               │
│  │    (GCR)     │        │                 │               │
│  └──────────────┘        └─────────────────┘               │
└─────────────────────────────────────────────────────────────┘
```

## Security Architecture

### Local Development

```
┌─────────────────────────────────────────────────────────┐
│                    Security Layers                       │
│                                                           │
│  1. Network Isolation                                    │
│     └─ Docker bridge network (internal only)            │
│                                                           │
│  2. Container Isolation                                  │
│     └─ Non-root users in containers                     │
│     └─ Read-only root filesystem where possible         │
│                                                           │
│  3. Environment Variables                                │
│     └─ Secrets stored in .env (not committed)           │
│                                                           │
│  4. Health Checks                                        │
│     └─ Automatic restart on failure                     │
└─────────────────────────────────────────────────────────┘
```

### Production (Cloud)

```
┌─────────────────────────────────────────────────────────┐
│                    Security Layers                       │
│                                                           │
│  1. Network Security                                     │
│     └─ VPC/VNet isolation                               │
│     └─ Security Groups / NSG rules                      │
│     └─ Private subnets for databases                    │
│                                                           │
│  2. Secrets Management                                   │
│     └─ AWS Secrets Manager / Azure Key Vault / GCP SM   │
│     └─ IAM roles for service authentication             │
│                                                           │
│  3. Data Encryption                                      │
│     └─ TLS/SSL for data in transit                      │
│     └─ Encryption at rest for databases                 │
│                                                           │
│  4. Access Control                                       │
│     └─ Least privilege IAM policies                     │
│     └─ MFA for administrative access                    │
│                                                           │
│  5. Monitoring & Logging                                 │
│     └─ CloudWatch / Azure Monitor / Cloud Logging       │
│     └─ Audit logs enabled                               │
└─────────────────────────────────────────────────────────┘
```

## Scalability

### Horizontal Scaling

```
                    Load Balancer
                         |
        ┌────────────────┼────────────────┐
        |                |                |
    App Instance 1   App Instance 2   App Instance N
        |                |                |
        └────────────────┼────────────────┘
                         |
            ┌────────────┴────────────┐
            |                         |
    PostgreSQL (RDS)          Redis (ElastiCache)
```

### Vertical Scaling

Adjust resources in:
- Docker Compose: `deploy.resources.limits`
- Cloud: Instance size in deployment configs

## Monitoring Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Monitoring Stack                      │
│                                                           │
│  ┌──────────────┐     ┌──────────────┐                 │
│  │ Application  │────▶│   Logs       │                 │
│  │   Metrics    │     │ Aggregation  │                 │
│  └──────────────┘     └──────────────┘                 │
│                                                           │
│  ┌──────────────┐     ┌──────────────┐                 │
│  │  Container   │────▶│   Metrics    │                 │
│  │   Health     │     │  Dashboard   │                 │
│  └──────────────┘     └──────────────┘                 │
│                                                           │
│  ┌──────────────┐     ┌──────────────┐                 │
│  │  Database    │────▶│   Alerting   │                 │
│  │   Metrics    │     │    System    │                 │
│  └──────────────┘     └──────────────┘                 │
└─────────────────────────────────────────────────────────┘
```

## CI/CD Pipeline (Recommended)

```
┌─────────────────────────────────────────────────────────┐
│                    CI/CD Pipeline                        │
│                                                           │
│  1. Code Push                                            │
│     └─ GitHub repository                                 │
│                                                           │
│  2. Build                                                │
│     └─ Docker image build                               │
│     └─ Run tests                                         │
│     └─ Security scan                                     │
│                                                           │
│  3. Push                                                 │
│     └─ Push to container registry                       │
│                                                           │
│  4. Deploy                                               │
│     └─ Update cloud service                             │
│     └─ Run smoke tests                                  │
│                                                           │
│  5. Monitor                                              │
│     └─ Health checks                                    │
│     └─ Rollback if needed                               │
└─────────────────────────────────────────────────────────┘
```

## Performance Considerations

### Database Optimization

- Connection pooling
- Indexed queries
- Query optimization
- Regular VACUUM operations

### Caching Strategy

- Redis for session storage
- Cache frequently accessed data
- Set appropriate TTL values
- Cache invalidation on updates

### Application Optimization

- Async operations
- Load balancing
- Resource limits
- Health checks

## Disaster Recovery

### Backup Strategy

```
Daily Backups ─────▶ Retention: 7 days
Weekly Backups ────▶ Retention: 4 weeks
Monthly Backups ───▶ Retention: 12 months
```

### Recovery Time Objective (RTO)

- Local: < 5 minutes
- Cloud: < 15 minutes

### Recovery Point Objective (RPO)

- Database: < 24 hours (daily backups)
- Can be improved with continuous backup solutions

## Future Enhancements

1. **Kubernetes Migration**: Move from Docker Compose to Kubernetes for better orchestration
2. **Service Mesh**: Implement Istio or Linkerd for microservices communication
3. **Observability**: Add Prometheus, Grafana, and Jaeger
4. **API Gateway**: Implement Kong or AWS API Gateway
5. **Message Queue**: Add RabbitMQ or AWS SQS for async processing
6. **CDN**: Implement CloudFront, Azure CDN, or Cloud CDN
7. **Auto-scaling**: Implement advanced auto-scaling based on custom metrics

## References

- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [12-Factor App](https://12factor.net/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Azure Architecture Center](https://docs.microsoft.com/azure/architecture/)
- [GCP Architecture Framework](https://cloud.google.com/architecture/framework)
