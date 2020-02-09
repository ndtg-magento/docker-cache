FROM php:7.3-fpm-alpine

MAINTAINER Nguyen Tuan Giang "https://github.com/ntuangiang"

ENV MAGENTO_VERSION=2.3.3

ENV DOCUMENT_ROOT=/usr/share/nginx/html

# Install package

RUN apk add --update --no-cache freetype \
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
    libjpeg-turbo-dev \
    redis mysql mysql-client vim

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

RUN pecl install \
    redis

RUN docker-php-ext-enable \
    redis

RUN apk del .phpize-deps \
    && apk del --no-cache \
       libpng-dev \
       libxslt-dev \
       freetype-dev \
       libjpeg-turbo-dev \
    && rm -rf /var/cache/apk/*

# Install Magento
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Save Cache
COPY ./docker/magento/auth.json /root/.composer/
RUN composer create-project --repository=https://repo.magento.com/ magento/project-community-edition=${MAGENTO_VERSION} ${DOCUMENT_ROOT}/cache
RUN rm -rf ${DOCUMENT_ROOT}/cache

# Copy Scripts
COPY ./docker/rootfs /rootfs
COPY ./docker/php/php.ini "${PHP_INI_DIR}/php.ini"

COPY ./docker/docker-redis-entrypoint /usr/local/bin/docker-redis-entrypoint
COPY ./docker/docker-mysql-entrypoint /usr/local/bin/docker-mysql-entrypoint

RUN chmod u+x /rootfs/* \
            /usr/local/bin/docker-redis-entrypoint \
            /usr/local/bin/docker-mysql-entrypoint

RUN ln -s /rootfs/magento:setup /usr/local/bin/magento:setup
RUN ln -s /rootfs/magento:install /usr/local/bin/magento:install

WORKDIR ${DOCUMENT_ROOT}

RUN addgroup mysql mysql

# Create a user group 'xyzgroup'
RUN addgroup -S magento

# Create a user 'appuser' under 'xyzgroup'
RUN adduser -SD magento magento

RUN chown -R magento:magento ${DOCUMENT_ROOT}/

RUN ln -s ${DOCUMENT_ROOT}/bin/magento /usr/local/bin/magento

USER magento
