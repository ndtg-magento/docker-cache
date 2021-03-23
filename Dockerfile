FROM php:7.4-fpm

MAINTAINER Nguyen Tuan Giang "https://github.com/ntuangiang"

ENV DOCUMENT_ROOT=/usr/share/nginx/html

ENV MAGENTO_VERSION=2.4.2

ENV MARIADB_MAJOR=10.5

ENV MARIADB_VERSION=1:10.5.4+maria~focal

# Install package
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libjpeg-dev \
    zlib1g-dev \
    libzip-dev \
    libgmp-dev \
    libldap2-dev \
    libmcrypt-dev \
    zlib1g-dev \
    libicu-dev \
    libxslt-dev \
    libxml2-dev \
    unzip curl apt-utils git netcat \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-freetype --with-jpeg

# Install PHP package
RUN docker-php-ext-install -j$(nproc) iconv gd

RUN docker-php-ext-install \
    pdo \
    pdo_mysql \
    zip \
    bcmath \
    intl \
    soap \
    xsl \
    sockets

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Prepare Install Magento
COPY ./docker/magento/auth.json /root/.composer/
COPY ./docker/php/php.ini "${PHP_INI_DIR}/php.ini"

# Save Cache
RUN composer create-project --repository=https://repo.magento.com/ magento/project-community-edition=$MAGENTO_VERSION $DOCUMENT_ROOT/cache
RUN rm -rf $DOCUMENT_ROOT/cache

WORKDIR ${DOCUMENT_ROOT}
