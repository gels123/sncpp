#!/bin/bash

docker rm -f redis-cluster1
docker run -d --name redis-cluster1 --network net4gamesvr -p 6381:6379 \
    -e REDIS_REPLICATION_MODE="master" \
    -e REDIS_PASSWORD="pwd123" \
    -e REDIS_DISABLE_COMMANDS="FLUSHDB,FLUSHALL,KEYS" \
    -v /Users/gels/Documents/work/dockerapp/redis-cluster1-data:/bitnami/redis/data \
    bitnami/redis:6.2.16

docker rm -f redis-cluster1-slave
docker run -d --name redis-cluster1-slave --network net4gamesvr -p 6382:6379 \
    -e REDIS_REPLICATION_MODE="slave" \
    -e REDIS_MASTER_HOST="redis-cluster1" \
    -e REDIS_MASTER_PORT_NUMBER="6379" \
    -e REDIS_MASTER_PASSWORD="pwd123" \
    -e REDIS_PASSWORD="pwd123" \
    -e REDIS_DISABLE_COMMANDS="FLUSHDB,FLUSHALL,KEYS" \
    -v /Users/gels/Documents/work/dockerapp/redis-cluster1-slave-data:/bitnami/redis/data \
    bitnami/redis:6.2.16



docker rm -f mysql
docker run -d --name mysql -p 3307:3306 --network net4gamesvr \
    -e MYSQL_ROOT_USER="root" \
    -e MYSQL_ROOT_PASSWORD="root123" \
    -e MYSQL_USER="gamesvr" \
    -e MYSQL_PASSWORD="pwd123" \
    -e MYSQL_BIND_ADDRESS="0.0.0.0" \
    -e MYSQL_AUTHENTICATION_PLUGIN="mysql_native_password" \
    -v /Users/gels/Documents/work/dockerapp/mysql-data:/bitnami/mysql/data \
    bitnami/mysql:8.0.40

