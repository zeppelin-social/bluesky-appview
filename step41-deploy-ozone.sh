#!/bin/bash

script_path="`realpath "$0"`"
script_dir="`dirname "$script_path"`"
. "$script_dir/utils.sh"

set -o allexport
. "$params_file"
set +o allexport

show_heading "Create ozone account" for ozone service/admin
make api_CreateAccount_ozone email=$OZONE_CONFIRMATION_ADDRESS handle=$OZONE_ADMIN_HANDLE || { show_error "Error creating ozone account:" "Please correct" ; exit 1 ; }

grep did:plc: data/accounts/${OZONE_ADMIN_HANDLE}.secrets >/dev/null || { show_error "Error creating ozone admin account" "did not found in file" ; exit 1 ; }
# ozone uses the same DID for  OZONE_SERVER_DID and OZONE_ADMIN_DIDS, at [HOSTING.md](https://github.com/bluesky-social/ozone/blob/main/HOSTING.md)
# FIXME: get OZONE_SERVER_DID and copy to OZONE_ADMIN_DIDS

show_heading "Deploy ozone container" for server $OZONE_SERVER_DID
make docker-start-bsky-ozone-nowatch OZONE_SERVER_DID=$OZONE_SERVER_DID OZONE_ADMIN_DIDS=$OZONE_SERVER_DID || { show_error "Error deploying ozone container:" "Please correct" ; exit 1 ; }

# FIXME: wait for ozone startup?

show_heading "Index Label Assignments" "into appview DB via subscribeLabels"
export PATH=$PATH:`pwd`/ops-helper/apiImpl/node_modules/.bin
./ops-helper/apiImpl/subscribeLabels2BskyDB.ts || { show_error "Error indexing label assignments:" "Please correct" ; exit 1 ; }

show_heading "Sign Ozone DidDoc" for ozone admin account
#    first, request and get PLC sign by email
make api_ozone_reqPlcSign handle=$OZONE_ADMIN_HANDLE password=$OZONE_ADMIN_PASSWORD || { show_error "Error signing Ozone DidDoc:" "Please correct" ; exit 1 ; }
# FIXME: get the plc token from the user somehow
#    update didDoc with above sign
make api_ozone_updateDidDoc plcSignToken=$OZONE_PLC_TOKEN handle=$OZONE_ADMIN_HANDLE ozoneURL=https://ozone.${DOMAIN}/ || { show_error "Error updating Ozone DidDoc:" "Please correct" ; exit 1 ; }

# 5) [optional] add member to the ozone team (i.e: add role to user):
#    valid roles are: tools.ozone.team.defs#roleAdmin | tools.ozone.team.defs#roleModerator | tools.ozone.team.defs#roleTriage
# make api_ozone_member_add   role=  did=did:plc:

