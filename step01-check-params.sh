#!/bin/bash

script_path="`realpath "$0"`"
script_dir="`dirname "$script_path"`"
. "$script_dir/utils.sh"

cd "$script_dir"
[ -f $params_file ] || { show_error "Params file not found" at $params_file ; exit 1 ; }

show_heading "Checking for required params" "in $params_file"
declare -a needed_params=(DOMAIN asof EMAIL4CERTS PDS_EMAIL_SMTP_URL FEEDGEN_EMAIL)
failures=
for needed_param in "${needed_params[@]}"
  do
    echo -n "Checking for $needed_param... "
    find_param="`grep "^$needed_param=." "$params_file" 2>/dev/null`"
    result=$?
    echo -n "`echo -n "$find_param" | head -n 1` "
    if [ $result == 0 ]
      then
        show_success
      else
        show_failure
        failures="$failures $needed_param"
      fi
  done

if [ "$failures" != "" ]
  then
    show_error "Params not found" "in $params_file: $failures"
    exit 1
  fi

set -o allexport
. "$params_file"
set +o allexport

show_heading "Showing configuration"
make echo

show_heading "Generating secrets"
make genSecrets

