#!/bin/bash

# echo "Start last migration"
#until vernemq ping
#do
#    echo "Couldn't reach MQTT. Sleeping."
#    sleep 1
#done
# TODO: This is copied to 20190324221228-grafana_and_jupyter-migrate.sh as well.
until mosquitto_pub -i test_connection -h mqtt -p 8883 -q 0 \
    -t test/network/up \
    -m "A messag.e" \
    -u $(cat /run/secrets/mqtt_username) \
    -P "$(cat /run/secrets/mqtt_password)" \
    --cafile /run/secrets/ca
do
    echo "Couldn't reach MQTT. Sleeping."
    sleep 1
done
# TODO: The above checks result in the request being sent and never recieved. 
# Figure out a better way to handle this. 
sleep 10

create_mqtt_user home_assistant "home_assistant"
create_mqtt_user node_red "node_red"
create_mqtt_user esphome "esphome"
