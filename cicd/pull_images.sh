#!/bin/bash

docker network create net4gamesvr

docker pull bitnami/redis:6.2.16
# docker pull bitnami/mongodb:5.0.24
docker pull mongodb/mongodb-community-server:6.0.15-ubi8
# docker pull bitnami/mysql:8.0.40
docker pull bitnami/elasticsearch:7.17.10


