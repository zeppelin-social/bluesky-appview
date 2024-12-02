#!/bin/bash

script_path="`realpath "$0"`"
script_dir="`dirname "$script_path"`"
. "$script_dir/utils.sh"

set -o allexport
. "$params_file"
set +o allexport

show_heading "Checking DNS" configuration
public_ip=`curl -s api.ipify.org/`
echo "Expected IP address is $public_ip"

# TODO: requires bind9-dnsutils
function check_dns_maps_to_here() {
  check_domain="$1"
  echo -n "Checking DNS for $check_domain... "
  resolved_ip="`dig +short -t a -q "$1" | tail -n 1`"
  if [ "$resolved_ip" == "$public_ip" ]
    then
      echo -n "$resolved_ip "
      show_success
      return 0
    else
      echo -n "$resolved_ip != $public_ip "
      show_failure
      return 1
    fi
}

check_dns_maps_to_here "${DOMAIN}"|| { show_error "Main Domain DNS is not configured:" "you will need to set this up yourself" ; exit 1 ; }
# this is to check there really is a wildcard domain configured
check_dns_maps_to_here "random-`pwgen 4`.${DOMAIN}" || { show_error "Wildcard DNS is not configured:" "you will need to set this up yourself" ; exit 1 ; }


