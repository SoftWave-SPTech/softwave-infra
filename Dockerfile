# softwave-infra/Dockerfile
FROM nginx:alpine

# (Opcional) instalar curl útil para debug (mantém a imagem pequena)
RUN apk add --no-cache curl

# Copia a configuração principal (caminho relativo ao build context)
COPY nginx/nginx.conf /etc/nginx/nginx.conf

# Caso tenha arquivos adicionais (ex.: conf.d, certificados, sites), copie também:
# COPY nginx/conf.d /etc/nginx/conf.d

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
