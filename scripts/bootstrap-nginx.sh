#!/bin/bash
# softwave-infra/scripts/bootstrap-nginx.sh
# Script para bootstrap da EC2 NGINX (sub-rede pública)

set -e

echo "🚀 Bootstrapping NGINX EC2..."

# Atualizar sistema
sudo yum update -y

# Instalar Nginx
sudo amazon-linux-extras install nginx1 -y

# Instalar Node.js (para servir React se necessário)
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
sudo yum install -y nodejs

# Instalar AWS CLI v2 (se não estiver instalado)
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
fi

# Criar diretórios
sudo mkdir -p /var/www/softwave-frontend
sudo mkdir -p /var/log/softwave
sudo chown -R ec2-user:ec2-user /var/www/softwave-frontend
sudo chown -R ec2-user:ec2-user /var/log/softwave

# Configurar firewall
if command -v firewall-cmd &> /dev/null; then
    sudo firewall-cmd --permanent --add-service=http
    sudo firewall-cmd --permanent --add-service=https
    sudo firewall-cmd --reload
else
    # Amazon Linux 2 usa iptables
    sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
    sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
    sudo service iptables save || sudo iptables-save > /etc/iptables/rules.v4 || true
fi

# Backup configuração padrão do Nginx
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup

# NOTA: A configuração nginx.conf deve ser copiada manualmente ou via S3
# Exemplo: sudo aws s3 cp s3://softwave-artifacts-prod/config/nginx.conf /etc/nginx/nginx.conf

# Habilitar e iniciar Nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Testar configuração
sudo nginx -t

echo "✅ NGINX bootstrap completed!"
echo "⚠️  Lembre-se de copiar o arquivo nginx.conf para /etc/nginx/nginx.conf antes de fazer reload!"

