#!/bin/sh

set -e

ELASTICSEARCH_DIR=/usr/share

cd $ELASTICSEARCH_DIR && \
  curl -L -O https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.8.1-linux-x86_64.tar.gz && \
  tar -xvf elasticsearch-7.8.1-linux-x86_64.tar.gz && \
  rm -rf elasticsearch-7.8.1-linux-x86_64.tar.gz && \
  ln -s /usr/share/elasticsearch-7.8.1/bin/elasticsearch /usr/local/bin/elasticsearch

chmod -R 777 /usr/share/elasticsearch-7.8.1/

groupadd -g 1000 elasticsearch
useradd -d /home/elasticsearch -s /bin/bash -u 1000 -g 1000 elasticsearch