#!/bin/sh
set -e

HOST_DOMAIN="host.docker.internal"

if [ -z "${MAGENTO_DATABASE_PORT}" ]; then
    MAGENTO_DATABASE_PORT=3306
fi

if [ -z "${MAGENTO_DATABASE_HOST}" ]; then
    MAGENTO_DATABASE_HOST=${HOST_DOMAIN}
fi

if [ -z "${MAGENTO_BASE_URL}" ]; then
    MAGENTO_BASE_URL="http://127.0.0.1"
else
    BASE_URL=${MAGENTO_BASE_URL#*//}
    BASE_URL=${BASE_URL%/*}

    echo -e "127.0.0.1\t${BASE_URL}" >> /etc/hosts
fi

if [ -z "${MAGENTO_DATABASE_USER}" ]; then
    MAGENTO_DATABASE_USER="root"
fi

if [ -z "${MAGENTO_ADMIN_USER}" ]; then
    MAGENTO_ADMIN_USER="admin"
fi

if [ -z "${MAGENTO_ADMIN_PWD}" ]; then
    MAGENTO_ADMIN_PWD="admin123"
fi

if [ -z "${MAGENTO_ADMIN_EMAIL}" ]; then
    MAGENTO_ADMIN_EMAIL="admin@example.com"
fi

if [ -z "${MAGENTO_ADMIN_FIRST_NAME}" ]; then
    MAGENTO_ADMIN_FIRST_NAME="Admin"
fi

if [ -z "${MAGENTO_ADMIN_LAST_NAME}" ]; then
    MAGENTO_ADMIN_LAST_NAME="User"
fi

echo "Dump database"
mysqldump -u$MAGENTO_DATABASE_USER -p$MAGENTO_DATABASE_PWD $MAGENTO_DATABASE_DB | gzip > "${DOCUMENT_ROOT}"/magento2.sql.gz
