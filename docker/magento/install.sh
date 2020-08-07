#!/bin/bash

set -e

MAGENTO_VERSION=$1
DOCUMENT_ROOT=$2

ln -s /rootfs/magento/setup/magento-setup.sh /usr/local/bin/magento:setup
ln -s /rootfs/magento/setup/magento-install.sh /usr/local/bin/magento:install

cp /rootfs/magento/auth.json /root/.composer/

composer create-project --repository=https://repo.magento.com/ magento/project-community-edition=$MAGENTO_VERSION $DOCUMENT_ROOT/cache
rm -rf $DOCUMENT_ROOT/cache

