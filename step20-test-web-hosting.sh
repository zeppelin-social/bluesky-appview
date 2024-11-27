#!/bin/bash

script_path="`realpath "$0"`"
script_dir="`dirname "$script_path"`"
. "$script_dir/utils.sh"

set -o allexport
. "$params_file"
set +o allexport

show_heading "Starting test web containers" "to check caddy configuration"

make docker-start-nowatch f=./docker-compose-debug-caddy.yaml services=

show_heading "Wait for startup" "of test web containers"
wait_for_container caddy
if [ "$EMAIL4CERT" != "internal" ]
  then
    show_heading "Artificial delay" "to allow letsencrypt to work"
    sleep 20
  fi

show_heading "Checking test web containers"

# test HTTPS and WSS with your docker environment
failures=
curl -L "https://test-wss.${DOMAIN}/" || { show_warning "Error testing https" "to test-wss.${DOMAIN}" ; failures="$failures https://test-wss" ; }
echo test successful | websocat "wss://test-wss.${DOMAIN}/ws" || { show_warning "Error testing wss" "to test-wss.${DOMAIN}" ; failures="$failures wss://test-wss" ; }

# test reverse proxy mapping if it works as expected for bluesky
#  those should be redirect to PDS
{ curl -L "https://pds.${DOMAIN}/xrpc/any-request" | jq ; } || { show_warning "Error testing xrpc" "to pds.${DOMAIN}" ; failures="$failures https://pds/xrpc" ; }
random_name=`pwgen 6`
{ curl -L "https://random-${random_name}.pds.${DOMAIN}/xrpc/any-request" | jq ; } || { show_warning "Error testing xrpc" "to random-${random_name}.pds.${DOMAIN}" ; failures="$failures https://random/xrpc" ; }

#  those should be redirect to social-app
{ curl -L "https://pds.${DOMAIN}/others" | jq ; } || { show_warning "Error testing https" "to pds.${DOMAIN}/others" ; failures="$failures https://pds/others" ; }
{ curl -L "https://random-${random_name}.pds.${DOMAIN}/others" | jq ; } || { show_warning "Error testing https" "to random-${random_name}.pds.${DOMAIN}" ; failures="$failures https://random/others" ; }

if [ "$failures" = "" ]
  then
    show_info "Tests passed"
  else
    show_error "Tests failed:" "$failures"
    show_info "Debug before proceeding:" "test containers left running"
    exit 1
  fi


show_heading "Stopping test web containers" "without persisting data"

make    docker-stop-with-clean f=./docker-compose-debug-caddy.yaml

