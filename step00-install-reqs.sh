#!/bin/bash

script_path="`realpath "$0"`"
script_dir="`dirname "$script_path"`"
. "$script_dir/utils.sh"

show_heading "Setting up apt packages" that are requirements for building running and testing these docker images
sudo apt update
# make is used to run setup scripts etc
# pwgen is used to generate new securish passwords
sudo apt install -y make pwgen
# these are used to be able to build and run websocat for testing
sudo apt install -y cargo curl build-essential libssl-dev pkg-config
# building cargo
cargo install --features=ssl websocat

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

