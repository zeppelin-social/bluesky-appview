#!/bin/bash

script_path="`realpath "$0"`"
script_dir="`dirname "$script_path"`"
. "$script_dir/utils.sh"

set -o allexport
. "$params_file"
set +o allexport

show_heading "Starting test web containers" "to check caddy configuration"

make docker-start-nowatch f=./docker-compose-debug-caddy.yaml services=

show_heading "Checking test web containers"

# test HTTPS and WSS with your docker environment
curl -L "https://test-wss.${DOMAIN}/"
echo test successful | websocat "wss://test-wss.${DOMAIN}/ws"

# test reverse proxy mapping if it works as expected for bluesky
#  those should be redirect to PDS
curl -L "https://pds.${DOMAIN}/xrpc/any-request" | jq
curl -L "https://random-`pwgen 6`.pds.${DOMAIN}/xrpc/any-request" | jq

#  those should be redirect to social-app
curl -L "https://pds.${DOMAIN}/others" | jq
curl -L "https://random-`pwgen 6`.pds.${DOMAIN}/others" | jq

# TODO: actually check these responses

show_heading "Stopping test web containers" "without persisting data"

make    docker-stop-with-clean f=./docker-compose-debug-caddy.yaml

