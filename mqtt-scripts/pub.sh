#!/usr/bin/env bash

function create()
{
    mosquitto_pub -i portainer_create_secret -h mqtt -p 8883 -r -q 1 \
        -i "Portainer_pub" \
        -t portainer/secret/create/${stackname}/vault/mqtt_username \
        -m "New Username" \
        -u $(cat /run/secrets/mqtt_username) \
        -P "$(cat /run/secrets/mqtt_password)" \
        -d \
        --cafile /run/secrets/ca 
}
create
