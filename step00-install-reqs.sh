#!/bin/bash

script_path="`realpath "$0"`"
script_dir="`dirname "$script_path"`"
. "$script_dir/utils.sh"

show_heading "Setting up apt packages" that are requirements for building running and testing these docker images
if dpkg-query -l make pwgen jq yq
  then
    show_info "No install required:" all packages already installed
  else
    sudo apt update
    # make is used to run setup scripts etc
    # pwgen is used to generate new securish passwords
    # jq and yq are used in extracted json and yaml data for config and tests
    sudo apt install -y make pwgen jq yq
  fi

show_heading "Setting up websocat" directly from executable download, in /usr/local/bin
if [ -x /usr/local/bin/websocat ] && websocat --version
  then
    show_info "No install required:" websocat already present
  else
    (sudo curl -o /usr/local/bin/websocat -L https://github.com/vi/websocat/releases/download/v1.13.0/websocat.x86_64-unknown-linux-musl; sudo chmod a+x /usr/local/bin/websocat)
  fi

show_heading "Setting up nvm" and node
# installing nvm and node
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
# this is manually sourcing nvm so we can use its functions
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm install 20

show_heading "Building internal tool" "ops-helper/apiImpl" 
(
  cd ops-helper/apiImpl
  nvm use 20
  npm install
)

