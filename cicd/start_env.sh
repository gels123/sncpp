#!/bin/bash

if [[ ! -d "~/dockerapp/config" ]]; then
    mkdir -p ~/dockerapp/config
fi
if [[ ! -f "~/dockerapp/config/keyfile.key" ]]; then
    openssl rand -base64 756 > ~/dockerapp/config/keyfile.key && chmod 600 ~/dockerapp/config/keyfile.key
fi

docker-compose -f docker-compose.yml up -d