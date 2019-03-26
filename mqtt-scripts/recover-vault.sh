#!/usr/bin/env bash
# TODO: Figure out how to auto include this.
source ${lib_path}create-secret.sh
if [ -f "/var/run/technocore/.env" ]; then
    source  /var/run/technocore/.env
fi

vault_i() {
    docker exec -i $containerId vault "$@"
}

# TODO: This is duplicated in portainer/mqtt-scripts/renew-tls.sh
# $1: service name. Examples are "vault", "emq"
create_tls(){
    local alt_names="${1}.local,${1}"
    if [ "$1" == "nginx" ]; then
        alt_names="${1}.local,${1},${stack_name},${stack_name}.local,${stack_name}.${domain},${DOCKER_HOSTNAME},${DOCKER_HOSTNAME}.local,${DOCKER_HOSTNAME}.${domain}"
    fi
    local tlsResponse=$(vault_i write $insecure -format=json ca/issue/tls common_name="${1}.${domain}" alt_names="$alt_names" ttl=720h format=pem)
    # TODO: This check doesn't seem to be working.
    if [ $? != 0 ];
    then
        echo "Error connecting to vault."
        return;
    fi
    local tlsCert=$(grep -Eo '"certificate":.*?[^\\]",' <<< "$tlsResponse" | cut -d \" -f 4)
    local tlsKey=$(grep -Eo '"private_key":.*?[^\\]",' <<< "$tlsResponse" | cut -d \" -f 4)
    local tlsCa=$(grep -Eo '"issuing_ca":.*?[^\\]",' <<< "$tlsResponse" | cut -d \" -f 4)

    create_secret ${1} key "$tlsKey"
    create_secret ${1} cert_bundle "${tlsCert}\n${tlsCa}"
}

remove_temp_containers(){
    if [ $containerId ]; then
        docker stop $containerId > /dev/null
    fi
}

cd /var/run
# TODO: Make this run if unseal and vault_token don't already exist. Exit with note about rebooting and needing to run again. 
#docker service update --secret-add source=${stack_name}_vault_unseal,target=unseal --secret-add source=${stack_name}_vault_token,target=vault_token ${stack_name}_portainer
containerId=$(docker run --rm -d --name ${stack_name}_vault -e "VAULT_CONFIG_DIR=/vault/setup" -e "VAULT_ADDR=http://127.0.0.1:8200" -v ${stack_name}_vault:/vault/file ${image_provider}/technocore-vault:${TAG})
# Wait for the vault container to come up.
sleep 10
vault_i operator unseal "$(cat /run/secrets/unseal)"
vault_i login $insecure "$(cat /run/secrets/vault_token)"
create_tls vault

# Cleanup
remove_temp_containers
#docker service update --secret-rm ${stack_name}_vault_unseal --secret-rm ${stack_name}_vault_token ${stack_name}_portainer
