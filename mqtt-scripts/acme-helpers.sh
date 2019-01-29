#!/usr/bin/env bash

# TODO: Figure out how to get this sourced automatically. 
source ${lib_path}create-secret.sh

# $1: The acme_env file
    # acme_env file should contain ACME_FLAGS, all other vars are optional. 
    # It should support any .env vars that acme.sh supports. 
    # ACME_FLAGS="--dns dns_duckdns"
    # ACME_DOMAIN="technocore.duckdns.org"
    # DuckDNS_Token="YOUR-ASSIGNED-TOKEN"
# $2: 'issue' if the cert should be created, 'renew' otherwise. 
function update_duckdns_tls() 
{
    set -a
    eval "$1"
    set +a
    
    hostname_trimmed=$(echo ${DOCKER_HOSTNAME} | cut -d"." -f 1)
    if ! acme.sh --dnssleep 30 --test --$2 -d $ACME_DOMAIN $ACME_FLAGS # $ACME_CHALLENGE_ALIAS 
    then
        return 1
    fi

    # Update secrets
    create_secret nginx cert_bundle "$(cat /acme.sh/${ACME_DOMAIN}/fullchain.cer)"
    create_secret nginx key "$(cat /acme.sh/${ACME_DOMAIN}/${ACME_DOMAIN}.key)"

    # Update DuckDNS entry with the internal IP address. 
    ip=$(ping -c 1 ${hostname_trimmed} | awk -F '[()]' '/PING/{print $2}')
    # How to silence curl: https://unix.stackexchange.com/questions/196549/hide-curl-output
    echo url="https://www.duckdns.org/update?domains=${ACME_DOMAIN}&token=${DuckDNS_Token}&ip=${ip}" | curl -s -K - > /dev/null
    return 0
}
