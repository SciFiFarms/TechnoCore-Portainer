#!/usr/bin/env bash

# $1: Topic to subscribe to
# $2+: Command to run upon message reception.
function subscribe()
{
    #echo "Starting sleep"
    # TODO: Turn this into a check or retry. 
    sleep 120
    #echo "Finished sleep"
    sub_topic="$1"
    shift

    while read RAW_DATA;
    do
        #echo "RAW_DATA: $RAW_DATA"
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

function create_secret()
{
    cmd=${topic/portainer/docker}
    cmd=$(echo "$cmd" | tr "/" " " ) 
    echo "$cmd"

    mount_point=$(echo "$cmd" | rev | cut -d" " -f1 | rev)
    service_name=$(echo "$cmd" | rev | cut -d" " -f2 | rev)
    stack_name=$(echo "$cmd" | rev | cut -d" " -f3 | rev)
    # TODO: Currently some swarm service names have been abrivated 
    # (ha=home-assistant, nr=node-red). I'm moving towards the full names 
    # instead, but until that happens, I need to support some way to provide
    # two different service names. Once that is complete, this can be simplified
    # to a single service name. 
    secret_service_name=$(echo "$service_name" | cut -d"&" -f1 )
    swarm_service_name=$(echo "$service_name" | cut -d"&" -f2 )
    # TODO: This check isn't actually working. 
    if [ ! -z ${swarm_service_name} ]; then
        echo "swarm_service_name exists"
        service_name=$swarm_service_name
    else
        echo "swarm_service_name doesn't exist"
    fi

    secret_name="${stack_name}_${secret_service_name}_${mount_point}"

    # TODO: Instead of passing in the service, it would be better to look up all 
    # the services that use the given secret_name.
    # Can use docker secret rm ${secret_name} to get the list of services that 
    # use ${secret_name}
    # This may be a better version: https://gist.github.com/jamiejackson/a1818acedaeb9c3cd70bafac86a0100b
    #service_name=$(echo "$cmd" | rev | cut -d" " -f3 | rev)
    echo "Creating/updating secret: $secret_name for service $service_name"

    echo "mount_point: $mount_point"
    echo "Secret_name: $secret_name"
    echo "Service_name: $service_name"

    echo -e "$message" | docker secret create ${secret_name}.temp -
    docker service update --detach=false --secret-rm ${secret_name} --secret-add source=${secret_name}.temp,target=${mount_point} ${stack_name}_${service_name}
    docker secret rm ${secret_name}
    echo -e "$message" | docker secret create ${secret_name} - 
    docker service update --detach=false --secret-rm ${secret_name}.temp --secret-add source=${secret_name},target=${mount_point} ${stack_name}_${service_name} 
    docker secret rm ${secret_name}.temp
}

subscribe portainer/secret/create/# create_secret