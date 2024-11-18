#!/bin/bash

script_path="`realpath "$0"`"
script_dir="`dirname "$script_path"`"
. "$script_dir/utils.sh"

set -o allexport
. "$params_file"
set +o allexport

export u=firstever
test_account_handle=${u}.pds.${DOMAIN}
test_account_password=`pwgen 16`
test_account_email=${u}@example.com
show_heading "Test creating account" $handle with password $test_account_password and email $test_account_email 
make api_CreateAccount handle=$test_account_handle password=$test_account_password email=$test_account_email resp=./data/accounts/${u}.secrets


# FIXME: wait for jetstream?



