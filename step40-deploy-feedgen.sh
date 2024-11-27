#!/bin/bash

script_path="`realpath "$0"`"
script_dir="`dirname "$script_path"`"
. "$script_dir/utils.sh"

set -o allexport
. "$params_file"
set +o allexport

feedgen_file="data/accounts/${REBRANDING_NAME:-bluesky}-feedgen.did"
grep '^null$' "$feedgen_file" >/dev/null 2>/dev/null && { sed -i '/^null/d' "$feedgen_file" ; show_warning "Nulls found" "in $feedgen_file; they have been removed" ; exit 1 ; }
[[ -e "$feedgen_file" && ! -s "$feedgen_file" ]] && { show_warning "Removing empty feedgen file" "$feedgen_file" ; rm "$feedgen_file" ; } 
if [[ -f "$feedgen_file" ]]
  then
    FEEDGEN_PUBLISHER_DID="`<"${feedgen_file}"`"
    show_info "Using existing feedgen account" "$FEEDGEN_PUBLISHER_DID"
  else
    show_heading "Create feedgen account"
    make exportDidFile="${feedgen_file}" api_CreateAccount_feedgen || { show_error "Error creating account" "for feedgen" ; exit 1 ; }
  fi
# show_heading "Wait here"
# sleep 20
export FEEDGEN_PUBLISHER_DID="`<"${feedgen_file}"`"
[ "$FEEDGEN_PUBLISHER_DID" == "" ] && { show_error "Error getting account DID" "for feedgen" ; exit 1 ; }

show_heading "Deploy feedgen container" for feed $FEEDGEN_PUBLISHER_DID
make docker-start-bsky-feedgen-nowatch FEEDGEN_PUBLISHER_DID=$FEEDGEN_PUBLISHER_DID

show_heading "Wait for startup" "of feedgen"
wait_for_container feed-generator

show_heading "Announce existence of feed"
make publishFeed

