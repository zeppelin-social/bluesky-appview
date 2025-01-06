#!/bin/bash

script_path="`realpath "$0"`"
script_dir="`dirname "$script_path"`"
. "$script_dir/utils.sh"

set -o allexport
. "$params_file"
set +o allexport

show_heading "Fetching unbranded containers" "for required services with generic builds"
branded_services=$(yq '.services | to_entries | .[] | .key as $parent | select(.value["image"] | contains("${DOMAIN}"))|$parent' docker-compose.yaml | cut -d'"' -f2)
unbranded_services=$(yq '.services | to_entries | .[] | .key as $parent | select(.value["image"] | contains("${DOMAIN}") | not)|$parent' docker-compose.yaml | cut -d'"' -f2)
echo branded $branded_services
echo unbranded $unbranded_services
make docker-pull-unbranded unbranded_services="${unbranded_services//$'\n'/ }" || { show_error "Fetching Containers failed:" "Please see error above" ; exit 1 ; }

show_heading "Deploy required containers" "(database, caddy etc)"
make docker-start || { show_error "Required Containers failed:" "Please see error above" ; exit 1 ; }

show_heading "Deploy bluesky containers" "(plc, bgs, appview, pds, ozone, ...)"
make docker-start-bsky || { show_error "BlueSky Containers failed:" "Please see error above" ; exit 1 ; }

show_heading "Wait for startup" "of social app"
# could also wait for Sbsky ?=pds bgs bsky social-app palomar
# this requires a health check to be defined on the container
wait_for_container social-app


