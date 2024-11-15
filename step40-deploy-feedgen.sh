#!/bin/bash

script_path="`realpath "$0"`"
script_dir="`dirname "$script_path"`"
. "$script_dir/utils.sh"

set -o allexport
. "$params_file"
set +o allexport

show_heading "Create feedgen account"
make exportDidFile=feedgen.did api_CreateAccount_feedgen || { show_error "Error creating account" "for feedgen" ; exit 1 ; }
export FEEDGEN_PUBLISHER_DID="`<feedgen.did`"
[ "$FEEDGEN_PUBLISHER_DID" == "" ] && { show_error "Error getting account DID" "for feedgen" ; exit 1 ; }

show_heading "Deploy feedgen container" for feed $FEEDGEN_PUBLISHER_DID
make docker-start-bsky-feedgen-nowatch FEEDGEN_PUBLISHER_DID=$FEEDGEN_PUBLISHER_DID

show_heading "Wait for startup" "of feedgen"
wait_for_container feed-generator

show_heading "Announce existence of feed"
make publishFeed

