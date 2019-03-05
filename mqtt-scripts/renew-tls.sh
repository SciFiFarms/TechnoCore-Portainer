#!/usr/bin/env bash
# TODO: Figure out how to auto include this.
source ${lib_path}create-secret.sh
source  /var/run/.env

# This list is duplicated in install.sh. 
# TODO: I've just removed the nginx service. Should actually look at env var to make that judgement. 
# TODO: I've also removed the portainer service. Should consider making it http.
# vault needs to be last so that it can create the secrets, and then restart itself.
declare -a services=(home_assistant mqtt home_assistant_db node_red docs vault )

function run_vault()
{
    docker exec -it $(docker service ps -f desired-state=running --no-trunc ${stack_name}_vault | grep ${stack_name} | tr -s " " | cut -d " " -f 2).$(docker service ps -f desired-state=running --no-trunc ${stack_name}_vault | grep ${stack_name} | tr -s " " | cut -d " " -f 1) /bin/sh -c "$@"
}

# $1: service name. Examples are "vault", "emq"
create_tls(){
    local alt_names="${1}.local,${1}"
    if [ "$1" == "nginx" ]; then
        alt_names="${1}.local,${1},${stack_name},${stack_name}.local,${stack_name}.${domain},${DOCKER_HOSTNAME},${DOCKER_HOSTNAME}.local,${DOCKER_HOSTNAME}.${domain}"
    fi
    local tlsResponse=$(run_vault "vault write $insecure -format=json ca/issue/tls common_name=\"${1}.${domain}\" alt_names=\"$alt_names\" ttl=720h format=pem")
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

# Create TLS certs for services.
create_TLS_certs(){
    run_vault -c 'vault login $(cat /run/secrets/vault_token)' > /dev/null
    for service in "${services[@]}"
    do
            echo "Creating TLS certs for ${stack_name}_$service"
            create_tls $service 
    done
}

unseal_vault(){
    echo "Unsealing Vault"
    run_vault 'vault operator unseal -tls-skip-verify "$(cat /run/secrets/vault_unseal)"'
}


# TODO: Make an actual flag for insecure mode. --insecure. 
# In order to use this flag, you MUST be running the command from the service.
# run_portainer
# ./renew-tls.sh --insecure
if [ "${1}" == "--insecure" ]; then
    insecure="-tls-skip-verify"
fi

create_TLS_certs
