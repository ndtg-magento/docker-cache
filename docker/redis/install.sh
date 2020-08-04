#!/bin/bash

set -e

apt-get install redis-server -y

pecl install redis
docker-php-ext-enable redis