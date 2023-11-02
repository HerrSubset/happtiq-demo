FROM nginx:1.25

COPY default-nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html
