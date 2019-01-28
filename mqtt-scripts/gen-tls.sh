#!/usr/bin/env bash
# TODO: Figure out how to auto include this.
source ${lib_path}acme-helpers.sh
source ${lib_path}create-secret.sh

# TODO: Consider having these optionally passed in via command line or ENV instead of forcing from CMD. 
#       It would allow me to not have to input the creds every time. Nice. GOOD FIRST TICKET
# https://stackoverflow.com/questions/3980668/how-to-get-a-password-from-a-shell-script-without-echoing
read -p "DuckDNS Sub-domain - example: technocore.duckdns.org should enter \"technocore\" : " domain
read -s -p "DuckDNS Token: " token
echo ""

# acme_env file should contain ACME_FLAGS, all other vars are optional. 
# It should support any .env vars that acme.sh supports. 
# ACME_FLAGS="--dns dns_duckdns"
# ACME_CHALLENGE_ALIAS="--challenge-alias technocore.duckdns.org"
# DuckDNS_Token="YOUR-ASSIGNED-TOKEN"

# https://stackoverflow.com/questions/23929235/multi-line-string-with-extra-space-preserved-indentation
# TODO: Turn into snippet
acme_secret=$(cat <<-END
    ACME_FLAGS="--dns dns_duckdns"
    ACME_DOMAIN="${domain}.duckdns.org"
    DuckDNS_Token="$token"
END
)
update_duckdns_tls "$acme_secret" issue 
create_secret portainer acme_env "$acme_secret"
exit 0
