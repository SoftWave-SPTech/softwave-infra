# softwave-infra/Dockerfile
FROM nginx:alpine

# Copia a pasta nginx (contendo nginx.conf) do contexto
# OBS: caminho relativo ao build context (./softwave-infra)
COPY nginx/nginx.conf /etc/nginx/nginx.conf

# opcional: copiar outros arquivos de sites, logs config etc.
# COPY nginx/conf.d /etc/nginx/conf.d

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
