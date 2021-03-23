#!/bin/sh

set -e

MAGENTO_VERSION=$1
DOCUMENT_ROOT=$2

ln -s /rootfs/magento/setup.sh /usr/local/bin/magento:setup
ln -s /rootfs/magento/install.sh /usr/local/bin/magento:install
ln -s /rootfs/magento/dumn-db.sh /usr/local/bin/magento:dump:db
ln -s /rootfs/magento/crontab.sh /usr/local/bin/magento:crontab

ln -s ${DOCUMENT_ROOT}/bin/magento /usr/local/bin/magento


