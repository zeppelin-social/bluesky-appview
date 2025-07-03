#!/usr/bin/env bash

GENERATE_PASS="openssl ecparam --name secp256k1 --genkey --noout --outform DER | tail --bytes=+8 | head --bytes=32 | xxd --plain --cols 32"

password_names=(
    POSTGRES_PASSWORD
    BSKY_ADMIN_PASSWORDS
    BSKY_SERVICE_SIGNING_KEY
    RELAY_ADMIN_KEY
)

for name in "${password_names[@]}"; do
    eval "${name}=$(eval "${GENERATE_PASS}")"
done

echo "Generated secrets:"
for name in "${password_names[@]}"; do
    echo "${name}=${!name}"
done
