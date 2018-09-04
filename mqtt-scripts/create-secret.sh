#!/usr/bin/env bash

# $1: Topic to subscribe to
# $2+: Command to run upon message reception.
function subscribe()
{
    sub_topic="$1"
    shift

    while read RAW_DATA;
    do
        local topic=$(echo "$RAW_DATA" | cut -d" " -f1 )
        local message=$(echo "$RAW_DATA" | cut -d" " -f2- )
        "$@"
    done < <( mosquitto_sub -i "portainer_sub" -h "mqtt" -p 8883 -q 1 \
        -t "$sub_topic" \
        -u $(cat /run/secrets/mqtt_username) \
        -P $(cat /run/secrets/mqtt_password) \
        -v \
        --cafile /run/secrets/ca )
}

function deploy()
{
    env $(cat /etc/.env | grep ^[A-Z] | xargs) /docker stack deploy --compose-file /etc/docker-compose.yml ${stackname}
}

function create_secret()
{
    cmd=${topic/portainer/docker}
    cmd=$(echo "$cmd" | tr "/" " " ) 
    echo "$cmd"
    /docker service rm althing_dev_ha
    /${cmd/create/rm}
    echo -e "$message" | /$cmd -

    sleep 5
    deploy

    #/docker service scale althing_dev_ha=1
}

subscribe portainer/secret/create/# create_secret