#!/bin/sh
set -e

# Import Logger
. /rootfs/shell/logger.sh

# Import Setup
. /rootfs/magento/setup/production.sh

# Import Service
. /rootfs/mysql/entrypoint.sh &
. /rootfs/elasticsearch/entrypoint.sh &
. /rootfs/redis/entrypoint.sh &

note "[i] Sleeping 2 sec before setup."
sleep 2

note "${DOCUMENT_ROOT}/bin/magento -V"
"${DOCUMENT_ROOT}"/bin/magento -V

magento_setup

if [ "${MAGENTO_EXPORT_DB}" = true ]
then
    note "Dump Database"
    . /rootfs/magento/dump-db.sh
fi

note "cp ${DOCUMENT_ROOT}/app/etc/env.php ${DOCUMENT_ROOT}/app/etc/env.php.template"
cp "${DOCUMENT_ROOT}"/app/etc/env.php "${DOCUMENT_ROOT}"/app/etc/env.php.template

