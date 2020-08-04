#!/bin/sh
set -e

VERSION=7.8.1
DOWNLOAD_URL="https://artifacts.elastic.co/downloads/elasticsearch"
ES_TARBAL="${DOWNLOAD_URL}/elasticsearch-oss-${VERSION}-no-jdk-linux-x86_64.tar.gz"
ES_TARBALL_ASC="${DOWNLOAD_URL}/elasticsearch-oss-${VERSION}-no-jdk-linux-x86_64.tar.gz.asc"
EXPECTED_SHA_URL="${DOWNLOAD_URL}/elasticsearch-oss-${VERSION}-no-jdk-linux-x86_64.tar.gz.sha512"
ES_TARBALL_SHA="f0caa06c1172b25d8f9cb9ddced72185aaaabb1b6d7f31fe1ba67172346236651ca3bc560e7ef206b4bf9521f228d46ee98df2e41b129253215135b583086ccc"
GPG_KEY="46095ACC8548582C1A2699A9D27D666CD88E42B4"

apk add --no-cache openjdk11-jre-headless su-exec

apk add --no-cache -t .build-deps wget ca-certificates gnupg openssl \
  && set -ex \
  && cd /tmp \
  && echo "===> Install Elasticsearch..." \
  && wget --progress=bar:force -O elasticsearch.tar.gz "$ES_TARBAL"; \
  if [ "$ES_TARBALL_SHA" ]; then \
  echo "$ES_TARBALL_SHA *elasticsearch.tar.gz" | sha512sum -c -; \
  fi; \
  if [ "$ES_TARBALL_ASC" ]; then \
  wget --progress=bar:force -O elasticsearch.tar.gz.asc "$ES_TARBALL_ASC"; \
  export GNUPGHOME="$(mktemp -d)"; \
  ( gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEY" \
  || gpg --keyserver pgp.mit.edu --recv-keys "$GPG_KEY" \
  || gpg --keyserver keyserver.pgp.com --recv-keys "$GPG_KEY" ); \
  gpg --batch --verify elasticsearch.tar.gz.asc elasticsearch.tar.gz; \
  rm -rf "$GNUPGHOME" elasticsearch.tar.gz.asc || true; \
  fi; \
  tar -xf elasticsearch.tar.gz \
  && ls -lah \
  && mv elasticsearch-$VERSION /usr/share/elasticsearch \
  && adduser -D -h /usr/share/elasticsearch elasticsearch \
  && echo "===> Creating Elasticsearch Paths..." \
  && for path in \
  /usr/share/elasticsearch/data \
  /usr/share/elasticsearch/logs \
  /usr/share/elasticsearch/config \
  /usr/share/elasticsearch/config/scripts \
  /usr/share/elasticsearch/tmp \
  /usr/share/elasticsearch/plugins \
  ; do \
  mkdir -p "$path"; \
  chown -R elasticsearch:elasticsearch "$path"; \
  done \
  && rm -rf /tmp/* /usr/share/elasticsearch/jdk \
  && apk del --purge .build-deps

# TODO: remove this (it removes X-Pack ML so it works on Alpine)
rm -rf /usr/share/elasticsearch/modules/x-pack-ml/platform/linux-x86_64