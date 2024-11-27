#!/bin/bash

script_path="`realpath "$0"`"
script_dir="`dirname "$script_path"`"
. "$script_dir/utils.sh"

set -o allexport
. "$params_file"
set +o allexport

if [ "$EMAIL4CERTS" == "internal" ]
  then
    show_heading "Setting up CA" "for self-signed certificates"

    make getCAcert
    [ "$NOINSTALLCERTS" != "true" ] && make installCAcert

    show_heading "Don't forget to install the certificate" "in $script_dir/certs/root.crt into your local web browser"
  else
    show_heading "Certificates will be auto-generated" "using let's encrypt, with $EMAIL4CERTS as the email address"
    echo "This should take place when starting up the test web containers"
  fi

