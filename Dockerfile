# Build stage
FROM node:18 as node-build

WORKDIR /app

# Copia archivos package.json y yarn.lock
COPY package.json yarn.lock ./

# Instala las dependencias de Node.js
RUN yarn install

# Copia el resto de la aplicación
COPY . .

# Construye el frontend
RUN yarn run build

# PHP Stage
FROM php:8.2-fpm

# Instala las extensiones necesarias
RUN apt-get update && apt-get install -y \
    libpng-dev libjpeg-dev libfreetype6-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo pdo_mysql

# Instala Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copia todos los archivos del backend
COPY --from=node-build /app /var/www/html

# Instala las dependencias de PHP
RUN composer install --no-interaction --optimize-autoloader --no-dev

# Copia el archivo de configuración .env y ejecuta los comandos de Laravel
COPY .env.example .env
RUN php artisan key:generate

# Nginx Stage
FROM nginx:1.25

COPY --from=php:8.2-fpm /var/www/html /var/www/html
COPY ./docker/nginx/default.conf /etc/nginx/conf.d/default.conf

# Expone el puerto 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
