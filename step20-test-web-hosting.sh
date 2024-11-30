#!/bin/bash

script_path="`realpath "$0"`"
script_dir="`dirname "$script_path"`"
. "$script_dir/utils.sh"

set -o allexport
. "$params_file"
set +o allexport

show_heading "Starting test web containers" "to check caddy configuration"

show_info "Stopping test web containers" "in case any are still running"
make docker-stop f=./docker-compose-debug-caddy.yaml services= || { show_warning "Error stopping services:" "please examine and fix" ; exit 1 ; }
show_info "Starting test web containers"
make docker-start-nowatch f=./docker-compose-debug-caddy.yaml services= || { show_error "Error starting containers:" "please examine and fix" ; exit 1 ; }

show_heading "Wait for startup" "of test web containers"
wait_for_container caddy || { show_warning "Error waiting for caddy:" "it may not have started correctly" ; exit 1 ; }

show_info "Current value of EMAIL4CERTS:" "$EMAIL4CERTS"
if [ "$EMAIL4CERTS" == "internal" ]
  then
    CURL_ARGS="--cacert `pwd`/certs/root.crt --cacert `pwd`/certs/intermediate.crt"
    show_info "Using CA Cert" "for tests: $CURL_ARGS"
  else
    show_heading "Artificial delay" "to allow letsencrypt to work"
    sleep 20
  fi

show_heading "Checking test web containers"

# test HTTPS and WSS with your docker environment
failures=
curl ${CURL_ARGS} -L "https://test-wss.${DOMAIN}/" || { show_warning "Error testing https" "to test-wss.${DOMAIN}" ; failures="$failures https://test-wss" ; }
echo test successful | websocat "wss://test-wss.${DOMAIN}/ws" || { show_warning "Error testing wss" "to test-wss.${DOMAIN}" ; failures="$failures wss://test-wss" ; }

# test reverse proxy mapping if it works as expected for bluesky
#  those should be redirect to PDS
{ curl ${CURL_ARGS} -L "https://pds.${DOMAIN}/xrpc/any-request" | jq ; } || { show_warning "Error testing xrpc" "to pds.${DOMAIN}" ; failures="$failures https://pds/xrpc" ; }
random_name=`pwgen 6`
{ curl ${CURL_ARGS} -L "https://random-${random_name}.pds.${DOMAIN}/xrpc/any-request" | jq ; } || { show_warning "Error testing xrpc" "to random-${random_name}.pds.${DOMAIN}" ; failures="$failures https://random/xrpc" ; }

#  those should be redirect to social-app
{ curl ${CURL_ARGS} -L "https://pds.${DOMAIN}/others" | jq ; } || { show_warning "Error testing https" "to pds.${DOMAIN}/others" ; failures="$failures https://pds/others" ; }
{ curl ${CURL_ARGS} -L "https://random-${random_name}.pds.${DOMAIN}/others" | jq ; } || { show_warning "Error testing https" "to random-${random_name}.pds.${DOMAIN}" ; failures="$failures https://random/others" ; }

if [ "$failures" = "" ]
  then
    show_info "Tests passed"
  else
    show_error "Tests failed:" "$failures"
    show_info "Debug before proceeding:" "test containers left running"
    exit 1
  fi


show_heading "Stopping test web containers" "without persisting data"

make docker-stop-with-clean f=./docker-compose-debug-caddy.yaml

