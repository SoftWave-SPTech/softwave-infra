# Dockerfile do Load Balancer Nginx
FROM nginx:alpine

# Copia o arquivo de configuração personalizado
COPY nginx.conf /etc/nginx/nginx.conf

# Expor porta 80
EXPOSE 80

# Comando padrão
CMD ["nginx", "-g", "daemon off;"]

