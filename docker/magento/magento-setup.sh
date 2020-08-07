#!/bin/sh
set -e

echo "magento:setup:db"
. /rootfs/mysql/entrypoint.sh mysqld

echo "magento:setup:redis"
. /rootfs/redis/entrypoint.sh 'redis-server'

echo "magento:setup:elasticsearch"
. /rootfs/elasticsearch/entrypoint.sh 'eswrapper'

. /rootfs/magento/setup/new.sh
. /rootfs/magento/setup/production.sh

sleep 2
echo "[i] Sleeping 2 sec before setup."

echo "${DOCUMENT_ROOT}/bin/magento -V"
"${DOCUMENT_ROOT}"/bin/magento -V

install_new_magento

echo "${DOCUMENT_ROOT}/bin/magento deploy:mode:set ${MAGENTO_MODE} --skip-compilation"
"${DOCUMENT_ROOT}"/bin/magento deploy:mode:set "${MAGENTO_MODE}" --skip-compilation

setup_static_content

echo "${DOCUMENT_ROOT}/bin/magento maintenance:enable"
"${DOCUMENT_ROOT}"/bin/magento maintenance:enable

echo "${DOCUMENT_ROOT}/bin/magento setup:db-schema:upgrade"
"${DOCUMENT_ROOT}"/bin/magento setup:db-schema:upgrade

echo "${DOCUMENT_ROOT}/bin/magento setup:db-data:upgrade"
"${DOCUMENT_ROOT}"/bin/magento setup:db-data:upgrade

echo "${DOCUMENT_ROOT}/bin/magento app:config:import --help >/dev/null 2>&1"
"${DOCUMENT_ROOT}"/bin/magento app:config:import --help >/dev/null 2>&1

echo "${DOCUMENT_ROOT}/bin/magento app:config:import"
"${DOCUMENT_ROOT}"/bin/magento app:config:import

echo "${DOCUMENT_ROOT}/bin/magento module:status --no-ansi"
"${DOCUMENT_ROOT}"/bin/magento module:status --no-ansi

echo "${DOCUMENT_ROOT}/bin/magento cache:flush"
"${DOCUMENT_ROOT}"/bin/magento cache:flush

echo "${DOCUMENT_ROOT}/bin/magento maintenance:disable"
"${DOCUMENT_ROOT}"/bin/magento maintenance:disable

if [ "${MAGENTO_EXPORT_DB}" = true ]; then
  . /rootfs/magento/setup/dump-db.sh
fi

production_permission

echo "cp ${MAGENTO_ENV} ${MAGENTO_ENV_TEMPLATE}"
cp "${MAGENTO_ENV}" "${MAGENTO_ENV_TEMPLATE}"

echo "chmod u+x ${DOCUMENT_ROOT}/bin/magento"
chmod u+x "${DOCUMENT_ROOT}"/bin/magento

