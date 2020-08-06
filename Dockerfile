FROM php:7.4-fpm

MAINTAINER Nguyen Tuan Giang "https://github.com/ntuangiang"

ENV MAGENTO_VERSION=2.4

ENV DOCUMENT_ROOT=/usr/share/nginx/html

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
    unzip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN pecl install redis

RUN docker-php-ext-configure gd \
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

RUN docker-php-ext-enable redis

# Install Elasticsearch
RUN cd /usr/share && \
    curl -L -O https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.8.1-linux-x86_64.tar.gz && \
    tar -xvf elasticsearch-7.8.1-linux-x86_64.tar.gz && \
    rm -rf elasticsearch-7.8.1-linux-x86_64.tar.gz && \
    ln -s /usr/share/elasticsearch-7.8.1/bin/elasticsearch /usr/local/bin/elasticsearch

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Save Cache
COPY ./docker/magento/auth.json /root/.composer/
RUN composer create-project --repository=https://repo.magento.com/ magento/project-community-edition=${MAGENTO_VERSION} ${DOCUMENT_ROOT}/cache
RUN rm -rf ${DOCUMENT_ROOT}/cache

# Copy Scripts
COPY ./docker/rootfs /rootfs
COPY ./docker/php/php.ini "${PHP_INI_DIR}/php.ini"

RUN chmod u+x /rootfs/*

RUN ln -s /rootfs/magento:setup /usr/local/bin/magento:setup
RUN ln -s /rootfs/magento:install /usr/local/bin/magento:install
RUN ln -s ${DOCUMENT_ROOT}/bin/magento /usr/local/bin/magento

# Create a user 'appuser' under 'xyzgroup'
RUN addgroup magento
RUN adduser -SD magento magento

RUN chown -R magento:magento ${DOCUMENT_ROOT}/

WORKDIR ${DOCUMENT_ROOT}

USER magento

