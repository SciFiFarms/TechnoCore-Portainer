#!/usr/bin/env bash

function create()
{
    mosquitto_pub -h mqtt -p 8883 -q 1 \
        -i "Portainer_pub" \
        -t portainer/secret/create/${stackname}_home_assistant_mqtt_username \
        -m "New Username" \
        -u $(cat /run/secrets/mqtt_username) \
        -P "$(cat /run/secrets/mqtt_password)" \
        -d \
        --cafile /run/secrets/ca 
}
create
