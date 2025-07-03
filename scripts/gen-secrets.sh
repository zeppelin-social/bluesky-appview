#!/usr/bin/env bash

GENERATE_PASS="openssl ecparam --name secp256k1 --genkey --noout --outform DER | tail --bytes=+8 | head --bytes=32 | xxd --plain --cols 32"

password_names=(
    POSTGRES_PASSWORD
    PDS_ADMIN_KEY
    PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX
    PDS_JWT_SECRET
    RELAY_ADMIN_KEY
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
