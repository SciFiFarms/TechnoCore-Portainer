#!/bin/bash
lib_path=/usr/share/mqtt-scripts/
source ${lib_path}create-secret.sh
# TODO: This is copied to shell-migrations/20180826175057-create-and-save-users-migrate.sh as well.
until mosquitto_pub -i test_connection -h mqtt -p 8883 -q 0 \
    -t test/mqtt/up \
    -m "A message" \
    -u $(cat /run/secrets/mqtt_username) \
    -P "$(cat /run/secrets/mqtt_password)" \
    --cafile /run/secrets/ca
do
    echo "Couldn't reach MQTT. Sleeping."
    sleep 1
done

# TODO: Copied from renew-tls.sh
function run_vault()
{
    docker exec $(docker service ps -f desired-state=running --no-trunc ${stack_name}_vault | grep ${stack_name} | tr -s " " | cut -d " " -f 2).$(docker service ps -f desired-state=running --no-trunc ${stack_name}_vault | grep ${stack_name} | tr -s " " | cut -d " " -f 1) /bin/sh -c "$@"
}

# $1: The number of characters to generate
# We have to use >&2, which sends output to stderr because we're passing 
# the password into the caller via stdout. Ugly, but functional.
generate_password(){
    local response
    echo "Creating password of length $1" >&2
    until response=$(run_vault "vault write -force -format=json /sys/tools/random/${1}")
    do
        echo "Couldn't reach Vault. Will retry after sleep." >&2
        sleep 5
    done
    local password=$(extract_from_json random_bytes "$response")
    echo "$password"
}


# If any of these need to change, you'll also need to update influxdb with the 
# new usernames and passwords. They are ignored after the DB is initialized.
generate_timeseries_credentials(){
    run_vault -c "vault login \$(cat /run/secrets/vault_token)"  > /dev/null
    local admin_password=$(generate_password 32)
    local grafana_password=$(generate_password 32)
    local home_assistant_password=$(generate_password 32)

    create_secret timeseries_db admin_username "tsadmin"
    create_secret timeseries_db admin_password "$admin_password"
    create_secret timeseries_db grafana_username "grafana"
    create_secret timeseries_db grafana_password "$grafana_password"
    create_secret timeseries_db home_assistant_username "home_assistant"
    create_secret timeseries_db home_assistant_password "$home_assistant_password"
    # TODO: Make this actually check when influx is accessible rather than 
    #       seeing it work with 10, and giving a 5 second buffer. Health check?
    sleep 15

    create_secret grafana timeseries_db_username "grafana"
    create_secret grafana timeseries_db_password "$grafana_password"
    create_secret home_assistant timeseries_db_username "home_assistant"
    create_secret home_assistant timeseries_db_password "$home_assistant_password"
} 

generate_timeseries_credentials

#if [ ! -f "/data/gen-secrets" ]; then
    ./renew-tls.sh
#else
#    echo "This is the first run, so no certificate generation needed."
#fi
