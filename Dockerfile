# Usar la imagen oficial de Nginx (servidor web ligero)
FROM nginx:alpine

# Copiar el código web a la carpeta pública de Nginx
COPY index.html /usr/share/nginx/html/

# Exponer el puerto 80 para que Dokploy enrute el tráfico
EXPOSE 80