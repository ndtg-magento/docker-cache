#!/bin/bash
set -e

if [ -z "${MAGENTO_CRONTAB_DISABLED}" ]; then
		MAGENTO_CRONTAB_DISABLED=false
fi

if [ $1 == "setup" ]
then
    magento_install_crontab
    magento_run_crontab
elif [ $1 == 'run' ]
then
    magento_run_crontab
fi

# Install crontab
magento_install_crontab() {
		if [ "${MAGENTO_CRONTAB_DISABLED}" = false ]; then
				echo "${DOCUMENT_ROOT}/bin/magento cron:install >/dev/null 2>&1"
				"${DOCUMENT_ROOT}"/bin/magento cron:install >/dev/null 2>&1
		fi
}

# Run contab
magento_run_crontab() {
		if [ "${MAGENTO_CRONTAB_DISABLED}" = false ]; then
				echo "${DOCUMENT_ROOT}/bin/magento cron:run >/dev/null 2>&1"
				"${DOCUMENT_ROOT}"/bin/magento cron:run >/dev/null 2>&1
		fi
}