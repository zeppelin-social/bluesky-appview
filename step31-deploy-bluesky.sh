#!/bin/bash

script_path="`realpath "$0"`"
script_dir="`dirname "$script_path"`"
. "$script_dir/utils.sh"

set -o allexport
. "$params_file"
set +o allexport

show_heading "Fetching containers" "for required services"
make docker-pull

show_heading "Deploy required containers" "(database, caddy etc)"
make docker-start-nowatch

show_heading "Deploy bluesky containers" "(plc, bgs, appview, pds, ozone, ...)"
make docker-start-bsky-nowatch

show_heading "Wait for startup" "of social app"
# could also wait for Sbsky ?=pds bgs bsky social-app palomar
# this requires a health check to be defined on the container
wait_for_container social-app


