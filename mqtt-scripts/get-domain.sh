#!/usr/bin/env bash

if [ -f /run/secrets/acme_env ]; then
    eval "$(cat /run/secrets/acme_env)"
    echo "$ACME_DOMAIN"
    exit 0
fi

exit 1
