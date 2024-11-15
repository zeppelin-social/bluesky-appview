#!/bin/bash

script_path="`realpath "$0"`"
script_dir="`dirname "$script_path"`"
. "$script_dir/utils.sh"

set -o allexport
. "$params_file"
set +o allexport

show_heading "Fetching source code" "from the different repositories"
make cloneAll

show_heading "Making work branches" "for the different repositories"
make createWorkBranch

show_heading "Patching social-app" "to change the branding"
[ "$REBRANDING_NAME" == "" ] && { show_error "Brand name undefined:" "please set REBRANDING_NAME in $params_file" ; exit 1 ; }
[ -d "$script_dir/../rebranding" ] || { show_error "rebranding missing:" "please obtain source" ; exit 1 ; }
(
  cd "$script_dir/repos/social-app"
  git checkout -b local-rebranding-$REBRANDING_NAME work
  "$script_dir/../rebranding/run-rewrite-selfhost.sh" $REBRANDING_NAME
  git commit -a -m "Automatic rebranding to $REBRANDING_NAME"
)


show_heading "Patching each repository" "with changes required for docker build"
# 0) apply mimimum patch to build images, regardless self-hosting.
#      as described in https://github.com/bluesky-social/atproto/discussions/2026 for feed-generator/Dockerfile etc.
# NOTE: this op checks out a new branch before applying patch, and stays on the new branch
make patch-dockerbuild

show_heading "Building social-app" "customized for domain $DOMAIN"
# 1) build social-app image, customized for domain
make build f=./docker-compose-builder.yaml services=social-app

# show_heading "Building other images" "without domain customization"
# 2) build images with original
# make build DOMAIN= f=./docker-compose-builder.yaml 


