#!/bin/bash

script_path="`realpath "$0"`"
script_dir="`dirname "$script_path"`"
. "$script_dir/utils.sh"

set -o allexport
. "$params_file"
set +o allexport

show_heading "Setting up CA" "for self-signed certificates"

make getCAcert
make installCAcert

echo "Don't forget to install the certificate in `$script_dir/certs/root.crt" into your local web browser"

