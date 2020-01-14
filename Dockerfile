FROM php:7.3-fpm-alpine

MAINTAINER Nguyen Tuan Giang "https://github.com/ntuangiang"

ENV MAGENTO_VERSION=2.3.3

ENV DOCUMENT_ROOT=/usr/share/nginx/html

# Install package
RUN apk add --no-cache freetype \
    libpng \
    libjpeg \
    libjpeg \
    libxslt \
    libjpeg-turbo \
    icu-dev \
    libzip-dev \
    libpng-dev \
    libxslt-dev \
    freetype-dev \
    libjpeg-turbo-dev

RUN apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS

RUN docker-php-ext-configure gd \
    --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ \
    && docker-php-ext-configure zip --with-libzip \
    && docker-php-ext-configure intl

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

RUN apk del .phpize-deps \
    && apk del --no-cache \
       libpng-dev \
       libxslt-dev \
       freetype-dev \
       libjpeg-turbo-dev \
    && rm -rf /var/cache/apk/*

# Install Magento
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

COPY ./docker/magento/auth.json /root/.composer/

# Save Cache
RUN composer create-project --repository=https://repo.magento.com/ magento/project-community-edition=${MAGENTO_VERSION} ${DOCUMENT_ROOT}/cache

RUN rm -rf ${DOCUMENT_ROOT}/cache

