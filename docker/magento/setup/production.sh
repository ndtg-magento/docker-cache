#!/bin/sh

set -e

# Main Setup
magento_setup() {
    HOST_DOMAIN="127.0.0.1"

    if [ -z "${MAGENTO_DATABASE_PORT}" ]
    then
        MAGENTO_DATABASE_PORT=3306
    fi

    if [ -z "${MAGENTO_DATABASE_HOST}" ]
    then
        MAGENTO_DATABASE_HOST=${HOST_DOMAIN}
    else
        echo -e "127.0.0.1\t${MAGENTO_DATABASE_HOST}" >> /etc/hosts
    fi

    if [ -z "${MAGENTO_BASE_URL}" ]
    then
        MAGENTO_BASE_URL="http://127.0.0.1"
    else
    	  BASE_URL=${MAGENTO_BASE_URL#*//}
        BASE_URL=${BASE_URL%/*}

    	  echo -e "127.0.0.1\t${BASE_URL}" >> /etc/hosts
    fi

    if [ -z "${MAGENTO_DATABASE_USER}" ]
    then
        MAGENTO_DATABASE_USER="root"
    fi

    if [ -z "${MAGENTO_ADMIN_USER}" ]
    then
        MAGENTO_ADMIN_USER="admin"
    fi

    if [ -z "${MAGENTO_ADMIN_PWD}" ]
    then
        MAGENTO_ADMIN_PWD="admin123"
    fi

    if [ -z "${MAGENTO_ADMIN_EMAIL}" ]
    then
        MAGENTO_ADMIN_EMAIL="admin@example.com"
    fi

    if [ -z "${MAGENTO_ADMIN_FIRST_NAME}" ]
    then
        MAGENTO_ADMIN_FIRST_NAME="Admin"
    fi

    if [ -z "${MAGENTO_ADMIN_LAST_NAME}" ]
    then
        MAGENTO_ADMIN_LAST_NAME="User"
    fi

    if [ -z "${MAGENTO_SEARCH_ENGINE}" ]
    then
        MAGENTO_SEARCH_ENGINE="elasticsearch7"
    fi

    if [ -z "${MAGENTO_SEARCH_ENGINE_HOST}" ]
    then
        MAGENTO_SEARCH_ENGINE_HOST="127.0.0.1"
    else
        echo -e "127.0.0.1\t${MAGENTO_SEARCH_ENGINE_HOST}" >> /etc/hosts
    fi

    if [ -z "${MAGENTO_SEARCH_ENGINE_PORT}" ]
    then
        MAGENTO_SEARCH_ENGINE_PORT=9200
    fi

    if [ -z "${MAGENTO_MODE}" ]
    then
        MAGENTO_MODE=production
    fi

    magento_wait_service_running ${MAGENTO_DATABASE_HOST} ${MAGENTO_DATABASE_PORT}
    note "Database already now."

    magento_wait_service_running ${MAGENTO_SEARCH_ENGINE_HOST} ${MAGENTO_SEARCH_ENGINE_PORT}
    note "Elasticsearch already now."

    note "[i] Sleeping 3 sec before setup."
    sleep 3

    note "${DOCUMENT_ROOT}/bin/magento setup:install --base-url=${MAGENTO_BASE_URL} \
        --db-host=${MAGENTO_DATABASE_HOST}:${MAGENTO_DATABASE_PORT} --db-name=${MAGENTO_DATABASE_DB} \
        --admin-firstname=${MAGENTO_ADMIN_FIRST_NAME} --admin-lastname=${MAGENTO_ADMIN_LAST_NAME} --admin-email=${MAGENTO_ADMIN_EMAIL} \
        --admin-user=${MAGENTO_ADMIN_USER} --admin-password=${MAGENTO_ADMIN_PWD} \
        --db-user=${MAGENTO_DATABASE_USER} --db-password=${MAGENTO_DATABASE_PWD} \
        --language=en_US --currency=USD --timezone=America/Chicago --use-rewrites=1 \
        --search-engine=${MAGENTO_SEARCH_ENGINE} --elasticsearch-host=${MAGENTO_SEARCH_ENGINE_HOST} \
        --elasticsearch-port=${MAGENTO_SEARCH_ENGINE_PORT}"

    ${DOCUMENT_ROOT}/bin/magento setup:install --base-url=${MAGENTO_BASE_URL} \
        --db-host=${MAGENTO_DATABASE_HOST}:${MAGENTO_DATABASE_PORT} --db-name=${MAGENTO_DATABASE_DB} \
        --admin-firstname=${MAGENTO_ADMIN_FIRST_NAME} --admin-lastname=${MAGENTO_ADMIN_LAST_NAME} --admin-email=${MAGENTO_ADMIN_EMAIL} \
        --admin-user=${MAGENTO_ADMIN_USER} --admin-password="${MAGENTO_ADMIN_PWD}" \
        --db-user=${MAGENTO_DATABASE_USER} --db-password="${MAGENTO_DATABASE_PWD}" \
        --language=en_US --currency=USD --timezone=America/Chicago --use-rewrites=1 \
        --search-engine=${MAGENTO_SEARCH_ENGINE} --elasticsearch-host=${MAGENTO_SEARCH_ENGINE_HOST} \
        --elasticsearch-port=${MAGENTO_SEARCH_ENGINE_PORT}

    note "Setting up cache..."
    magento_setup_cache

    note "${DOCUMENT_ROOT}/bin/magento deploy:mode:set ${MAGENTO_MODE} --skip-compilation"
    "${DOCUMENT_ROOT}"/bin/magento deploy:mode:set "${MAGENTO_MODE}" --skip-compilation

    note "Setup minify static file config"
    magento_setup_minify_static

    note "${DOCUMENT_ROOT}/bin/magento setup:di:compile --no-ansi"
    "${DOCUMENT_ROOT}"/bin/magento setup:di:compile --no-ansi

    note "Setting static file..."
    magento_setup_static_file

    note "${DOCUMENT_ROOT}/bin/magento maintenance:enable"
    "${DOCUMENT_ROOT}"/bin/magento maintenance:enable

    note "${DOCUMENT_ROOT}/bin/magento setup:db-schema:upgrade"
    "${DOCUMENT_ROOT}"/bin/magento setup:db-schema:upgrade

    note "${DOCUMENT_ROOT}/bin/magento setup:db-data:upgrade"
    "${DOCUMENT_ROOT}"/bin/magento setup:db-data:upgrade

    note "${DOCUMENT_ROOT}/bin/magento app:config:import --help >/dev/null 2>&1"
    "${DOCUMENT_ROOT}"/bin/magento app:config:import --help >/dev/null 2>&1

    note "${DOCUMENT_ROOT}/bin/magento app:config:import"
    "${DOCUMENT_ROOT}"/bin/magento app:config:import

    note "${DOCUMENT_ROOT}/bin/magento module:status --no-ansi"
    "${DOCUMENT_ROOT}"/bin/magento module:status --no-ansi

    note "${DOCUMENT_ROOT}/bin/magento cache:flush"
    "${DOCUMENT_ROOT}"/bin/magento cache:flush

    note "${DOCUMENT_ROOT}/bin/magento maintenance:disable"
    "${DOCUMENT_ROOT}"/bin/magento maintenance:disable

    note "Assign access permission"
    magento_setup_access_permission

    note "Setup successfully."

    note "[i] Sleeping 1 sec after setup."
    sleep 1
}

# Magento Setup Cache
magento_setup_cache() {
    magento_setup_cache_redis
    magento_setup_cache_varnish
}

# Magento Setup Redis Cache
magento_setup_cache_redis() {
    if [ "${MAGENTO_CACHE_REDIS_HOST}" ]
    then
        note "Setting redis cache..."

        echo -e "127.0.0.1\t${MAGENTO_CACHE_REDIS_HOST}" >> /etc/hosts

        if [ -z "${MAGENTO_CACHE_REDIS_PORT}" ]
        then
            MAGENTO_CACHE_REDIS_PORT=6379
        fi

        magento_wait_service_running ${MAGENTO_CACHE_REDIS_HOST} ${MAGENTO_CACHE_REDIS_PORT}
        note "Redis already now."

        note "${DOCUMENT_ROOT}/bin/magento setup:config:set --cache-backend=redis --cache-backend-redis-server=${MAGENTO_CACHE_REDIS_HOST} \
                          --cache-backend-redis-port=${MAGENTO_CACHE_REDIS_PORT} --cache-backend-redis-db=0"
        yes | "${DOCUMENT_ROOT}"/bin/magento setup:config:set --cache-backend=redis --cache-backend-redis-server=${MAGENTO_CACHE_REDIS_HOST} \
            --cache-backend-redis-port=${MAGENTO_CACHE_REDIS_PORT} --cache-backend-redis-db=0

        note "${DOCUMENT_ROOT}/bin/magento setup:config:set --page-cache=redis --page-cache-redis-server=${MAGENTO_CACHE_REDIS_HOST} \
                          --cache-backend-redis-port=${MAGENTO_CACHE_REDIS_PORT} --page-cache-redis-db=1"
        yes | "${DOCUMENT_ROOT}"/bin/magento setup:config:set --page-cache=redis --page-cache-redis-server=${MAGENTO_CACHE_REDIS_HOST} \
            --cache-backend-redis-port=${MAGENTO_CACHE_REDIS_PORT} --page-cache-redis-db=1

        note "${DOCUMENT_ROOT}/bin/magento setup:config:set --session-save=redis --session-save-redis-host=${MAGENTO_CACHE_REDIS_HOST} \
                          --session-save-redis-port=${MAGENTO_CACHE_REDIS_PORT} --session-save-redis-break-after-frontend=15 \
                          session-save-redis-timeout=5 --session-save-redis-log-level=3 --session-save-redis-db=2"
        yes | "${DOCUMENT_ROOT}"/bin/magento setup:config:set --session-save=redis --session-save-redis-host=${MAGENTO_CACHE_REDIS_HOST} \
            --session-save-redis-port=${MAGENTO_CACHE_REDIS_PORT} --session-save-redis-break-after-frontend=15 \
            --session-save-redis-log-level=3 --session-save-redis-db=2

        note "Redis cache installed"
    fi
}

# Setup Varnish Cache
magento_setup_cache_varnish() {
    if [ "${VARNISH_CACHE_ENABLED}" = true ]
    then
        note "Setting varnish cache..."

        note "${DOCUMENT_ROOT}/bin/magento config:set --scope=default --scope-code=0 system/full_page_cache/caching_application 2"
        "${DOCUMENT_ROOT}"/bin/magento config:set --scope=default --scope-code=0 system/full_page_cache/caching_application 2

        if [ "${VARNISH_HTTP_CACHE_HOST}" ]
        then
            note "${DOCUMENT_ROOT}/bin/magento setup:config:set --http-cache-hosts=${VARNISH_HTTP_CACHE_HOST}"
            yes | "${DOCUMENT_ROOT}"/bin/magento setup:config:set --http-cache-hosts="${VARNISH_HTTP_CACHE_HOST}"
        fi

      note "Varnish cache installed"
    fi
}

# Setup Static
magento_setup_static_file() {
    note "${DOCUMENT_ROOT}/bin/magento setup:static-content:deploy en_US"
    "${DOCUMENT_ROOT}"/bin/magento setup:static-content:deploy en_US

    note "${DOCUMENT_ROOT}/bin/magento setup:static-content:deploy en_AU"
    "${DOCUMENT_ROOT}"/bin/magento setup:static-content:deploy en_AU
}

# Save Static Config
magento_setup_minify_static() {
    if [ -z "${MAGENTO_MINIFY_STATIC_FILE}" ]
    then
        MAGENTO_MINIFY_STATIC_FILE=true
    fi

    if [ "${MAGENTO_THEME_ID}" ]
    then
        "${DOCUMENT_ROOT}"/bin/magento setup:config:set design/theme/theme_id "${VARNISH_HTTP_CACHE_HOST}"
    fi

    if [ "${MAGENTO_MINIFY_STATIC_FILE}" = true ]
    then
        note "${DOCUMENT_ROOT}/bin/magento config:set dev/js/enable_js_bundling 1"
        "${DOCUMENT_ROOT}"/bin/magento config:set dev/js/enable_js_bundling 1

        note "${DOCUMENT_ROOT}/bin/magento config:set dev/js/minify_files 1"
        "${DOCUMENT_ROOT}"/bin/magento config:set dev/js/minify_files 1

        note "${DOCUMENT_ROOT}/bin/magento config:set dev/js/merge_files 0"
        "${DOCUMENT_ROOT}"/bin/magento config:set dev/js/merge_files 0

        note "${DOCUMENT_ROOT}/bin/magento config:set dev/css/minify_files 1"
        "${DOCUMENT_ROOT}"/bin/magento config:set dev/css/minify_files 1

        note "${DOCUMENT_ROOT}/bin/magento config:set dev/css/merge_css_files 1"
        "${DOCUMENT_ROOT}"/bin/magento config:set dev/css/merge_css_files 1

        note "${DOCUMENT_ROOT}/bin/magento config:set dev/template/minify_html 1"
        "${DOCUMENT_ROOT}"/bin/magento config:set dev/template/minify_html 1

        note "${DOCUMENT_ROOT}/bin/magento config:set dev/static/sign 1"
        "${DOCUMENT_ROOT}"/bin/magento config:set dev/static/sign 1
    fi
}

# Add Permission
magento_setup_access_permission() {
    note "mkdir -p ${DOCUMENT_ROOT}/var/cache ${DOCUMENT_ROOT}/var/report ${DOCUMENT_ROOT}/var/tmp "${DOCUMENT_ROOT}"/app/code"
    mkdir -p "${DOCUMENT_ROOT}"/var/cache "${DOCUMENT_ROOT}"/var/report "${DOCUMENT_ROOT}"/var/tmp "${DOCUMENT_ROOT}"/app/code

    note "find ${DOCUMENT_ROOT}/app/code ${DOCUMENT_ROOT}/var/* ${DOCUMENT_ROOT}/vendor \
        ${DOCUMENT_ROOT}/pub/static ${DOCUMENT_ROOT}/app/etc ${DOCUMENT_ROOT}/generated/code  \
        ${DOCUMENT_ROOT}/generated/metadata \( -type f -or -type d \) -exec chmod g-w {} + \
        && chmod o+rwx ${DOCUMENT_ROOT}/app/etc/env.php"
    find "${DOCUMENT_ROOT}"/app/code "${DOCUMENT_ROOT}"/var/* "${DOCUMENT_ROOT}"/vendor \
        "${DOCUMENT_ROOT}"/pub/static "${DOCUMENT_ROOT}"/app/etc "${DOCUMENT_ROOT}"/generated/code  \
        "${DOCUMENT_ROOT}"/generated/metadata \( -type f -or -type d \) -exec chmod g-w {} + \
        && chmod o+rwx "${DOCUMENT_ROOT}"/app/etc/env.php

    note "find ${DOCUMENT_ROOT}/var \( -type d -or -type f \) -exec chmod 777 {} +;"
    find "${DOCUMENT_ROOT}"/var \( -type d -or -type f \) -exec chmod 777 {} +;
}

# Waiting Service
magento_wait_service_running() {
  local HOST=$1
  local PORT=$2

  until nc -z -v -w30 ${HOST} ${PORT}
  do
      note "Waiting for ${HOST}:${PORT} connection..."
      # wait for 5 seconds before check again
      sleep 5
  done
}