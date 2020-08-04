#!/bin/bash

set -e

# logging functions
mysql_log() {
	local type="$1"; shift
	printf '%s [%s] [Entrypoint]: %s\n' "$(date --rfc-3339=seconds)" "$type" "$*"
}
mysql_note() {
	mysql_log Note "$@"
}
mysql_warn() {
	mysql_log Warn "$@" >&2
}
mysql_error() {
	mysql_log ERROR "$@" >&2
	exit 1
}

temp_server_start() {
  service mysql start
}

_main() {
	# skip setup if they aren't running mysqld or want an option that stops mysqld
	if [ "$1" = 'mysqld' ]; then
		mysql_note "Entrypoint script for MySQL Server ${MARIADB_VERSION} started."

    mysql_note "Starting temporary server"
		temp_server_start "$@"
		mysql_note "Temporary server started."

		# Creates a custom database and user if specified
    if [ -n "$MAGENTO_DATABASE_DB" ]; then
      mysql_note "Creating database ${MAGENTO_DATABASE_DB}"
      mysql <<<"CREATE DATABASE IF NOT EXISTS \`$MAGENTO_DATABASE_DB\` ;"
    fi

    if [ -n "$MAGENTO_DATABASE_USER" ] && [ -n "$MAGENTO_DATABASE_PWD" ]; then
      mysql_note "Creating user ${MAGENTO_DATABASE_USER}"
      mysql <<<"CREATE USER '$MAGENTO_DATABASE_USER'@'%' IDENTIFIED BY '$MAGENTO_DATABASE_PWD' ;"

      if [ -n "$MAGENTO_DATABASE_DB" ]; then
        mysql_note "Giving user ${MAGENTO_DATABASE_USER} access to schema ${MAGENTO_DATABASE_DB}"
        mysql <<<"GRANT ALL ON \`${MAGENTO_DATABASE_DB//_/\\_}\`.* TO '$MAGENTO_DATABASE_USER'@'%' ;"
      fi

      mysql_note "Flush Privileges"
      mysql <<<"FLUSH PRIVILEGES ;"
    fi
	fi
}

# If we are sourced from elsewhere, don't perform any further actions
_main "$@"
