#!/usr/bin/env bash

GENERATE_PASS="openssl ecparam --name secp256k1 --genkey --noout --outform DER | tail --bytes=+8 | head --bytes=32 | xxd --plain --cols 32"

GENERATE_OPENSEARCH_PASS="pwgen -c -n -B -s -1 16 1 | sed 's/$/_/'"

password_names=(
    POSTGRES_PASSWORD
    BSKY_ADMIN_PASSWORDS
    BSKY_SERVICE_SIGNING_KEY
)

for name in "${password_names[@]}"; do
    eval "${name}=$(eval "${GENERATE_PASS}")"
done

echo "Generated secrets:"
for name in "${password_names[@]}"; do
    echo "${name}=${!name}"
done
echo "OPENSEARCH_PASSWORD=$(eval "${GENERATE_OPENSEARCH_PASS}")"
