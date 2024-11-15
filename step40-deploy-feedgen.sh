#!/bin/bash

script_path="`realpath "$0"`"
script_dir="`dirname "$script_path"`"
. "$script_dir/utils.sh"

set -o allexport
. "$params_file"
set +o allexport

show_heading "Create feedgen account"
make api_CreateAccount_feedgen
# FIXME: get FEEDGEN_PUBLISHER_DID

show_heading "Deploy feedgen container" for feed $FEEDGEN_PUBLISHER_DID
make docker-start-bsky-feedgen-nowatch FEEDGEN_PUBLISHER_DID=$FEEDGEN_PUBLISHER_DID

# FIXME: wait for feedgen?

show_heading "Announce existence of feed"
make publishFeed

