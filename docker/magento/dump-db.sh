#!/bin/bash
set -e

HOST_DOMAIN="127.0.0.1"

if [ -z "${MAGENTO_DATABASE_PORT}" ]; then
    MAGENTO_DATABASE_PORT=3306
fi

if [ -z "${MAGENTO_DATABASE_HOST}" ]; then
    MAGENTO_DATABASE_HOST=${HOST_DOMAIN}
fi

if [ -z "${MAGENTO_DATABASE_USER}" ]; then
    MAGENTO_DATABASE_USER="root"
fi

echo "Dump database to ${DOCUMENT_ROOT}/magento2.sql.gz"
mysqldump -u$MAGENTO_DATABASE_USER -p$MAGENTO_DATABASE_PWD $MAGENTO_DATABASE_DB | gzip > "${DOCUMENT_ROOT}"/magento2.sql.gz
