#!/bin/bash

script_path="`realpath "$0"`"
script_dir="`dirname "$script_path"`"
. "$script_dir/utils.sh"

set -o allexport
. "$params_file"
set +o allexport

show_heading "Create ozone account" for ozone service/admin
# FIXME: define OZONE_CONFIRMATION_ADDRESS
make api_CreateAccount_ozone email=$OZONE_CONFIRMATION_ADDRESS handle=$OZONE_ADMIN_HANDLE

# ozone uses the same DID for  OZONE_SERVER_DID and OZONE_ADMIN_DIDS, at [HOSTING.md](https://github.com/bluesky-social/ozone/blob/main/HOSTING.md)
# FIXME: get OZONE_SERVER_DID and copy to OZONE_ADMIN_DIDS

show_heading "Deploy ozone container" for server $OZONE_SERVER_DID
make docker-start-bsky-ozone-nowatch OZONE_SERVER_DID=$OZONE_SERVER_DID OZONE_ADMIN_DIDS=$OZONE_SERVER_DID

# FIXME: wait for ozone startup?

show_heading "Index Label Assignments" "into appview DB via subscribeLabels"
./ops-helper/apiImpl/subscribeLabels2BskyDB.ts

show_heading "Sign Ozone DidDoc" for ozone admin account
#    first, request and get PLC sign by email
make api_ozone_reqPlcSign handle=$OZONE_ADMIN_HANDLE password=$OZONE_ADMIN_PASSWORD
# FIXME: get the plc token from the user somehow
#    update didDoc with above sign
make api_ozone_updateDidDoc plcSignToken=$OZONE_PLC_TOKEN handle=$OZONE_ADMIN_HANDLE ozoneURL=https://ozone.$DOMAIN/

# 5) [optional] add member to the ozone team (i.e: add role to user):
#    valid roles are: tools.ozone.team.defs#roleAdmin | tools.ozone.team.defs#roleModerator | tools.ozone.team.defs#roleTriage
# make api_ozone_member_add   role=  did=did:plc:

