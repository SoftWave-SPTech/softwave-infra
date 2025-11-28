#!/bin/bash
# softwave-infra/scripts/bootstrap-backend.sh
# Script para bootstrap das EC2 Backend (sub-rede privada) - Docker Compose

set -e

echo "🚀 Bootstrapping Backend EC2 com Docker Compose..."

# Atualizar sistema
sudo yum update -y

# Instalar Docker
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

# Instalar Docker Compose v2
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verificar instalações
docker --version
docker-compose --version

# Instalar AWS CLI v2 (se não estiver instalado)
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
fi

# Criar diretórios
sudo mkdir -p /opt/softwave
sudo mkdir -p /var/log/softwave
sudo chown -R ec2-user:ec2-user /opt/softwave
sudo chown -R ec2-user:ec2-user /var/log/softwave

# Configurar firewall (permitir portas Docker apenas da VPC)
# Portas: 8081, 8082, 8083, 8084 - apenas da VPC 10.0.0.0/24
PORTS=(8081 8082 8083 8084)
if command -v firewall-cmd &> /dev/null; then
    for port in "${PORTS[@]}"; do
        sudo firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='10.0.0.0/24' port protocol='tcp' port='$port' accept"
    done
    sudo firewall-cmd --reload
else
    # Amazon Linux 2 usa iptables
    for port in "${PORTS[@]}"; do
        sudo iptables -A INPUT -p tcp --dport $port -s 10.0.0.0/24 -j ACCEPT
    done
    sudo service iptables save || sudo iptables-save > /etc/iptables/rules.v4 || true
fi

echo "✅ Docker e Docker Compose instalados!"
echo "⚠️  Próximos passos:"
echo "   1. Fazer logout e login novamente para grupo docker ter efeito (ou executar: newgrp docker)"
echo "   2. Baixar imagens Docker do ECR ou fazer build local"
echo "   3. Copiar docker-compose.prod.yml para /opt/softwave/"
echo "   4. Criar arquivo .env em /opt/softwave/.env com todas as variáveis"
echo "   5. Copiar systemd service para /etc/systemd/system/softwave-docker-compose.service"
echo "   6. Executar: sudo systemctl daemon-reload && sudo systemctl enable softwave-docker-compose && sudo systemctl start softwave-docker-compose"

