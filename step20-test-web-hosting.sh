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
show_info "Stopping main docker containers" "in case any are still running"
make docker-stop f=./docker-compose.yaml services= || { show_warning "Error stopping services:" "please examine and fix" ; exit 1 ; }
show_info "Starting test web containers"
make docker-start f=./docker-compose-debug-caddy.yaml services= || { show_error "Error starting containers:" "please examine and fix" ; exit 1 ; }

show_heading "Wait for startup" "of test web containers"
wait_for_container caddy || { show_warning "Error waiting for caddy:" "it may not have started correctly" ; exit 1 ; }

show_info "Current value of EMAIL4CERTS:" "$EMAIL4CERTS"
if [ "$EMAIL4CERTS" == "internal" ]
  then
    CURL_ARGS="--cacert `pwd`/certs/root.crt --cacert `pwd`/certs/intermediate.crt"
    show_info "Using CA Cert" "for tests: $CURL_ARGS"
  else
    show_heading "Artificial delay" "to allow letsencrypt to work"
    sleep 10
  fi

show_heading "Checking test web containers"

# test HTTPS and WSS with your docker environment
failures=

function test_curl_url() {
  query_url=https://$1
  test_name=$2
  result=undefined
  show_info "Testing $2" "at $query_url"
  curl ${CURL_ARGS} -L -s --show-error $query_url | jq
  curl_result="${PIPESTATUS[0]}"
  if [ "$curl_result" == "0" ]
    then
      show_success
    else
      show_warning "Error testing https" "to $1: returned $curl_result"
      failures="$failures $query_url"
    fi
}

test_curl_url test-wss.${DOMAIN}/ test-wss

echo test successful | websocat "wss://test-wss.${DOMAIN}/ws" || { show_warning "Error testing wss" "to test-wss.${DOMAIN}" ; failures="$failures wss://test-wss" ; }

# test on the social-app domain
test_curl_url ${SOCIAL_DOMAIN}/ social-app

# test reverse proxy mapping if it works as expected for bluesky
#  those should be redirect to PDS
test_curl_url ${PDS_DOMAIN}/xrpc/any-request pds/xrpc
random_name=`pwgen 6`
test_curl_url random-${random_name}.${PDS_DOMAIN}/xrpc/any-request random/xrpc

#  those should be redirect to social-app
test_curl_url ${PDS_DOMAIN}/others pds/others
test_curl_url random-${random_name}.${PDS_DOMAIN}/others random/others

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

