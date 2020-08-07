#!/bin/bash

set -e

apt-get update && apt-get install gosu mariadb-server -y

mkdir /docker-entrypoint-initdb.d

