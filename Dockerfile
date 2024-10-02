# Utiliza la imagen de PHP 8.2 con FPM
FROM php:8.2-fpm

# Establece el directorio de trabajo
WORKDIR /var/www

# Instala las dependencias del sistema necesarias
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    unzip \
    git \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd zip

# Instala las extensiones de PHP requeridas
RUN docker-php-ext-install pdo pdo_mysql

# Instala Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copia el resto de la aplicación primero
COPY . .

# Copia el archivo de configuración de Composer
COPY composer.json composer.lock ./

# Instala las dependencias de Composer
RUN composer install --no-interaction --optimize-autoloader --no-dev

# Copia el archivo .env
COPY .env.example .env

# Genera la clave de la aplicación (opcional)
RUN php artisan key:generate

# Establece el comando para iniciar PHP-FPM
CMD ["php-fpm"]
