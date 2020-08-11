#!/bin/bash
set -e

# Import Logger
. /rootfs/shell/logger.sh

# Import Setup
. /rootfs/magento/setup/production.sh

# Import Service
. /rootfs/mysql/entrypoint.sh mysqld &
. /rootfs/elasticsearch/entrypoint.sh &
. /rootfs/redis/entrypoint.sh redis-server &

note "[i] Sleeping 2 sec before setup."
sleep 2

note "${DOCUMENT_ROOT}/bin/magento -V"
"${DOCUMENT_ROOT}"/bin/magento -V

magento_setup

if [ "${MAGENTO_EXPORT_DB}" = true ]; then
    note "Dump Database"
    . /rootfs/magent-dump-db.sh
fi

note "cp ${MAGENTO_ENV} ${MAGENTO_ENV_TEMPLATE}"
cp "${MAGENTO_ENV}" "${MAGENTO_ENV_TEMPLATE}"

