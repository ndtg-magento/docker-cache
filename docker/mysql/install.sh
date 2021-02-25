#!/bin/sh

set -e

apt-get update && apt-get install mariadb-server -y

mkdir /docker-entrypoint-initdb.d

